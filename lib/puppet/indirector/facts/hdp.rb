require "puppet/node/facts"
require "puppet/indirector/facts/puppetdb"
require "puppet/indirector/facts/yaml"
require "puppet/util/profiler"
require "puppet/util/hdp"
require "json"
require "time"

# HDP Facts
class Puppet::Node::Facts::Hdp < Puppet::Node::Facts::Puppetdb
  desc "Save facts to HDP, then Puppetdb."

  include Puppet::Util::Hdp

  def get_trusted_info(node)
    trusted = Puppet.lookup(:trusted_information) do
      Puppet::Context::TrustedInformation.local(node)
    end
    trusted.to_h
  end

  def profile(message, metric_id, &block)
    message = "HDP: " + message
    arity = Puppet::Util::Profiler.method(:profile).arity
    case arity
    when 1
      Puppet::Util::Profiler.profile(message, &block)
    when 2, -2
      Puppet::Util::Profiler.profile(message, metric_id, &block)
    end
  end

  def save(request)
    profile("hdp#save", [:hdp, :facts, :save, request.key]) do
      begin
        Puppet.info "Submitting facts to HDP"
        current_time = Time.now
        submit_facts(request, current_time.utc)
      rescue StandardError => e
        Puppet.err "Could not send facts to HDP: #{e}
#{e.backtrace}"
      end
    end
    ## Data has been sent to HDP - now delete our hdp facts and forward to puppetdb
    request.instance.values.delete("hdp")
    super(request)
  end
end
