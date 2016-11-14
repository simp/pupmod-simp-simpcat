Puppet::Type.newtype(:simpcat_fragment) do
  @doc = "Create a SIMP concat fragment"

  newparam(:name, :namevar => true) do
    validate do |value|
      fail Puppet::Error, "name is missing group or name. Name format must be 'group+fragment_name'" if value !~ /.+\+.+/
      fail Puppet::Error, "name cannot include '../'!" if value =~ /\.\.\//
    end
  end

  newparam(:externally_managed, :boolean => true) do
    desc "Set to 'true' if you have something else managing the content of this
          file. The file will be created if it doesn't currently exist."

    newvalues(:true,:false)
    defaultto :false
  end

  newparam(:group) do
    desc "Stub parameter, don't assign values to this"

    defaultto "fake"

    munge do |value|
      @resource[:name].split('+').first
    end
  end

  newparam(:fragment) do
    desc "Stub parameter, don't assign values to this"

    defaultto "fake"

    munge do |value|
      @resource[:name].split('+')[1..-1].join('+')
    end
  end

  newproperty(:content) do
    defaultto('!!simpcat_fragment_undef_content')

    def retrieve
      return resource[:content]
    end

    def insync?(is)
      provider.register

      file = "#{Facter.value(:puppet_vardir)}/simpcat/fragments/#{resource[:group]}/#{resource[:fragment]}"
      return false unless File.exist?(file)

      if resource[:content] == '!!simpcat_fragment_undef_content' then
        true
      else
        File.read(file).chomp == resource[:content].chomp
      end
    end

    def sync
      provider.create
    end

    def change_to_s(currentvalue, newvalue)
      "executed successfully"
    end

  end

  # This is only here because, at this point, we can be sure that the catalog
  # has been compiled. This checks to see if we have a simpcat_build specified
  # for our particular simpcat_fragment group.
  autorequire(:file) do
    if catalog.resources.find_all { |r| r.is_a?(Puppet::Type.type(:simpcat_build)) and r[:name] == self[:group] }.empty? then
      err "No 'simpcat_build' specified for group #{self[:group]}!"
    end

    []
  end



  validate do
    if self[:externally_managed] == :false and self[:content] == '!!simpcat_fragment_undef_content' then
      fail Puppet::Error, "You must specify content"
    end
  end
end
