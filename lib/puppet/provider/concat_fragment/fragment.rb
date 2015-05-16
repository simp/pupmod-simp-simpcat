Puppet::Type.type(:concat_fragment).provide :concat_fragment do
  require 'fileutils'

  desc "concat_fragment provider"

  def create
    begin
      if @resource[:externally_managed] == :true then
        FileUtils.touch("#{Puppet[:vardir]}/concat/fragments/#{@resource[:group]}/#{@resource[:fragment]}")
      else
        fh = File.open("#{Puppet[:vardir]}/concat/fragments/#{@resource[:group]}/#{@resource[:fragment]}", "w")
        fh.puts @resource[:content]
        fh.close
      end

    rescue Exception => e
      fail Puppet::Error, e
    end
  end

  def register
    begin
      FileUtils.mkdir_p("#{Puppet[:vardir]}/concat/fragments/#{@resource[:group]}")

      frags_record = "#{Puppet[:vardir]}/concat/fragments/#{@resource[:group]}/.~concat_fragments"
      fh = File.open(frags_record,'a')
      fh.puts(@resource[:fragment])
      fh.close

    rescue Exception => e
      fail Puppet::Error, e
    end

  end

end
