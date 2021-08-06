require 'puppet/node'
require 'puppet/indirector/rest'

# HDP Indirector
class Puppet::Node::Hdp < Puppet::Indirector::REST
  def find(request); end

  def save(request); end

  def destroy(request); end
end
