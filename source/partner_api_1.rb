# Version 1
require 'invoca/metrics'

class PartnerApi
  include Invoca::Metrics::Source

  def initialize(domain, credentials)
    @domain, @credentials = domain, credentials
  end

  def availability_for_npa(npa)
    log_success_or_failure_metric("availability_for_npa") do
      availability_for_npa_before_metrics(npa)
    end
  end

  def place_order_for_npa_nxx(npa_nxx, quantity)
    log_success_or_failure_metric("place_order_for_npa_nxx") do
      place_order_for_npa_nxx_before_metrics(npa_nxx, quantity)
    end
  end

  def phone_numbers_for_order(order_id)
    log_success_or_failure_metric("phone_numbers_for_order") do
      phone_numbers_for_order_before_metrics(order_id)
    end
  end

private

  def log_success_or_failure_metric(metric_name)
    begin
      result = yield
      metrics.increment("partner_api.#{metric_name}.success")
      result
    rescue
      metrics.increment("partner_api.#{metric_name}.failure")
      raise
    end
  end


  def availability_for_npa_before_metrics(npa)
    response = remote_procedure("availableNpaNxx", verb: :get, query: { areaCode: npa })
    case response.code
    when "200"
      structured_response_body = Hash.from_xml(response.body)
      search_result = process_structured_response(structured_response_body, "SearchResultForAvailableNpaNxx", response)
      available_npa_nxx_list = process_structured_response(search_result, "AvailableNpaNxxList", response)
      Array.wrap(available_npa_nxx_list._?["AvailableNpaNxx"]).map do |entry|
        { :nxx => entry["Nxx"], :quantity => entry["Quantity"] }
      end
    else
      raise ApiError.new(response.code, response.body)
    end
  end

  def place_order_for_npa_nxx_before_metrics(npa_nxx, quantity)
    request_body = {
        :SiteId => site_id,
        :NPANXXSearchAndOrderType => { :NpaNxx => npa_nxx, :Quantity => quantity, :EnableLCA => false }
    }.to_xml(:root => "Order", :skip_types => true)

    response = remote_procedure("orders", verb: :post, body: request_body)

    response.code == "201" or raise ApiError.new(response.code, response.body)
    structured_response_body = Hash.from_xml(response.body)
    order_response = process_structured_response(structured_response_body, "OrderResponse", response)
    order = process_structured_response(order_response, "Order", response)
    id = process_structured_response(order, "id", response)

    id.presence or raise ApiError.new(response.code, response.body, "id of the order is blank")
  end

  def phone_numbers_for_order_before_metrics(order_id)
    response = remote_procedure("orders/#{order_id}", verb: :get)
    response.code == "200" or raise ApiError.new(response.code, response.body)

    structured_response_body = Hash.from_xml(response.body)
    order_response = process_structured_response(structured_response_body, "OrderResponse", response)

    error_code = Array.wrap(order_response["ErrorList"]._?["Error"]).map { |error| error["Code"] }.first

    case error_code
    when EMPTY_RESULTS_ERROR_CODE
      []
    when NilClass, PARTIAL_RESULTS_ERROR_CODE
      parse_phone_numbers(order_response, response)
    else
      raise ApiError.new(response.code, response.body, "Unexpected error code")
    end
  end

end
