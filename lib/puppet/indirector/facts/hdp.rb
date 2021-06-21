require 'puppet/indirector/facts/yaml'
require 'puppet/util/profiler'
require 'puppet/util/hdp'
require 'json'
require 'time'

# HDP Facts
class Puppet::Node::Facts::HDP < Puppet::Node::Facts::Yaml
  desc 'Save facts to HDP and then to yamlcache.'

  include Puppet::Util::HDP

  def profile(message, metric_id, &block)
    message = 'HDP: ' + message
    arity = Puppet::Util::Profiler.method(:profile).arity
    case arity
    when 1
      Puppet::Util::Profiler.profile(message, &block)
    when 2, -2
      Puppet::Util::Profiler.profile(message, metric_id, &block)
    end
  end

  def save(request)
    # yaml cache goes first
    super(request)

    profile('hdp_facts#save', [:hdp, :facts, :save, request.key]) do
      begin
        Puppet.info 'Submitting facts to HDP'
        current_time = Time.now
        send_facts(request, current_time.clone.utc)
      rescue StandardError => e
        Puppet.err "Could not send facts to HDP: #{e}\n#{e.backtrace}"
      end
    end
  end
end
