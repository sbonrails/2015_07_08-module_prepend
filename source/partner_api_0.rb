# Version 0
require 'invoca/metrics'

class PartnerApi
  include Invoca::Metrics::Source

  def initialize(domain, credentials)
    @domain, @credentials = domain, credentials
  end


  def availability_for_npa(npa)
    response = remote_procedure("availableNpaNxx", verb: :get, query: { areaCode: npa })
    case response.code
    when "200"
      structured_response_body = Hash.from_xml(response.body)
      search_result = process_structured_response(structured_response_body, "SearchResultForAvailableNpaNxx", response)
      available_npa_nxx_list = process_structured_response(search_result, "AvailableNpaNxxList", response)
      result = Array.wrap(available_npa_nxx_list._?["AvailableNpaNxx"]).map do |entry|
        { :nxx => entry["Nxx"], :quantity => entry["Quantity"] }
      end
    else
      raise ApiError.new(response.code, response.body)
    end
    metrics.increment("partner_api.availability_for_npa.success")
    result
  rescue
    metrics.increment("partner_api.availability_for_npa.failure")
    raise
  end


  def place_order_for_npa_nxx(npa_nxx, quantity)
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

    result = id.presence or raise ApiError.new(response.code, response.body, "id of the order is blank")

    metrics.increment("partner_api.place_order_for_npa_nxx.success")
    result
  rescue
    metrics.increment("partner_api.place_order_for_npa_nxx.failure")
    raise
  end


  def phone_numbers_for_order(order_id)
    response = remote_procedure("orders/#{order_id}", verb: :get)
    response.code == "200" or raise ApiError.new(response.code, response.body)

    structured_response_body = Hash.from_xml(response.body)
    order_response = process_structured_response(structured_response_body, "OrderResponse", response)

    error_code = Array.wrap(order_response["ErrorList"]._?["Error"]).map { |error| error["Code"] }.first

    result =
      case error_code
      when EMPTY_RESULTS_ERROR_CODE
        []
      when NilClass, PARTIAL_RESULTS_ERROR_CODE
        parse_phone_numbers(order_response, response)
      else
        raise ApiError.new(response.code, response.body, "Unexpected error code")
      end

    metrics.increment("partner_api.phone_numbers_for_order.success")
    result
  rescue
    metrics.increment("partner_api.phone_numbers_for_order.failure")
    raise
  end

end
