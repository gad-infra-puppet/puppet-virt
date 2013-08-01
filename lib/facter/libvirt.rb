# virt_libvirt.rb

class CachedLibvirtConnection
  @connection = nil
  @cached = false

  def self.get
    cache_connection if not @cached
    @connection
  end

  private

  def self.cache_connection
    require 'libvirt'
    @connection = Libvirt::open('qemu:///system')
    @cached = true
  rescue LoadError
    # ruby-libvirt not installed
    @connection = nil
    @cached = true
  rescue Libvirt::Error => e
    raise
  end
end

def libvirt_connect
  if block_given?
    begin
      c = nil
      require 'libvirt'
      yield c = Libvirt::open('qemu:///system')
    rescue LoadError
      # ruby-libvirt not installed
      yield nil
    rescue
      raise
    ensure
      c.close unless c.nil?
    end
  else
    CachedLibvirtConnection.get
  end
end

Facter.add("virt_libvirt") do
  setcode do
    begin
      require 'libvirt'
      true
    rescue LoadError
      false
    end
  end
end

Facter.add("virt_conn") do
  confine :virt_libvirt => true
  setcode do
    begin
      libvirt_connect { |c| true }
    rescue Libvirt::Error, NoMethodError
      false
    end
  end
end

Facter.add("virt_conn_type") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      libvirt_connect { |c| c.type.chomp }
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_hypervisor_version") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      libvirt_connect { |c| c.version.to_s.chomp }
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_libvirt_version") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      libvirt_connect { |c| c.libversion.to_s.chomp }
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_hostname") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      libvirt_connect { |c| c.hostname.chomp }
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_uri") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      libvirt_connect { |c| c.uri.chomp }
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_max_vcpus") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      libvirt_connect { |c| c.max_vcpus('qemu').to_s.chomp }
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_domains_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      domains = []
      libvirt_connect do |c| 
        c.list_domains.each do |domid|
          domains.concat([ c.lookup_domain_by_id(domid.to_i).name ])
        end
      end
      domains.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_domains_inactive") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      domains = []
      libvirt_connect do |c|
        c.list_defined_domains.each do |domid|
          domains.concat([ c.lookup_domain_by_id(domid.to_i).name ])
        end
      end
      domains.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_networks_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      networks = []
      libvirt_connect do |c|
        c.list_networks.each do |netname|
          networks.concat([ netname ])
        end
      end
      networks.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_networks_inactive") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      networks = []
      libvirt_connect do |c|
          c.list_defined_networks.each do |netname|
          networks.concat([ netname ])
        end
      end
      networks.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_nodes") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      nodes = []
      libvirt_connect do |c|
        c.list_nodedevices.each do |nodename|
          nodes.concat([ nodename ])
        end
      end
      nodes.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_nwfilters") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      nwfilters = []
      libvirt_connect do |c|
        c.list_nwfilters.each do |filtername|
          nwfilters.concat([ filtername ])
        end
      end
      nwfilters.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_secrets") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      secrets = []
      libvirt_connect do |c|
        c.list_secrets.each do |secret|
          secrets.concat([ secret ])
        end
      end
      secrets.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_storage_pools_active") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      pools = []
      libvirt_connect do |c|
        c.list_storage_pools.each do |pool|
          pools.concat([ pool ])
        end
      end
      pools.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end

Facter.add("virt_storage_pools_inactive") do
  confine :virt_libvirt => true
  confine :virt_conn => true
  setcode do
    begin
      pools = []
      libvirt_connect do |c|
        c.list_defined_storage_pools.each do |pool|
          pools.concat([ pool ])
        end
      end
      pools.join(',')
    rescue Libvirt::Error, NoMethodError
      nil
    end
  end
end
