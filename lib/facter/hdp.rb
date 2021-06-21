# Get information about HDP
require 'facter'
require 'json'

Facter.add(:hdp) do
  confine kernel: 'Linux'
  setcode do
    if Dir.exist?('/opt/puppetlabs/hdp')
      begin
        image_data = {}
        cmd_output = Facter::Core::Execution.execute("docker ps --all --no-trunc --format '{{ json . }}'").split("\n")
        containers = []
        cmd_output.each do |json_hash|
          data = JSON.parse(json_hash)
          containers.push(data)
        end

        containers.each do |container|
          key = container['Names']
          value = {}
          next unless key.start_with?('hdp_')
          value['image'] = container['Image'].split(':')[0]
          value['tag'] = container['Image'].split(':')[1]
          data = Facter::Core::Execution.execute("docker inspect --format '{{ json .Image }}' #{key}")
          value['sha'] = JSON.parse(data).split(':')[1]
          image_data[key.to_s] = value
        end

        image_data
      rescue
        nil
      end
    end
  end
end
