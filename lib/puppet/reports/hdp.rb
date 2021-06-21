require 'puppet'
require 'puppet/network/http_pool'
require 'puppet/util/hdp'
require 'uri'
require 'json'

Puppet::Reports.register_report(:hdp) do
  desc <<-DESC
    A copy of the standard http report processor except it sends a
    `application/json` payload to `:hdp_url`
  DESC

  include Puppet::Util::HDP

  def process
    # Add in pe_console & producer fields
    report_payload = JSON.parse(to_json)
    report_payload['pe_console'] = pe_console
    report_payload['producer'] = Puppet[:certname]

    hdp_urls = settings['hdp_urls']

    hdp_urls.each do |url|
      hdp_url = "#{url}/data"
      Puppet.info "HDP sending report to #{hdp_url}"
      send_to_hdp(hdp_url, report_payload)
    end
  end
end
