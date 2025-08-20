require 'json'

namespace :pl do
  desc "do a local build"
  task :local_build do
    # If we have a dirty source, bail, because changes won't get reflected in
    # the package builds
    Pkg::Util::Git.fail_on_dirty_source

    Pkg::Util::RakeUtils.invoke_task("package:tar")
    # where we want the packages to be copied to for the local build
    nested_output = '../../../output'
    pkg_path = '../pkg'
    staging_path = 'pkg_artifacts'
    FileUtils.cp(Dir.glob("pkg/*.gz").join(''), FileUtils.pwd)
    # unpack the tarball we made during the build step
    stdout, stderr, exitstatus = Pkg::Util::Execution.capture3(%(tar xf #{Dir.glob("*.gz").join('')}))
    Pkg::Util::Execution.success?(exitstatus) or raise "Error unpacking tarball: #{stderr}"
    Dir.chdir("#{Pkg::Config.project}-#{Pkg::Config.version}") do
      Pkg::Config.final_mocks.split(" ").each do |mock|
        platform = mock.split('-')[1..-2].join('-')
        platform_path = platform.gsub(/\-/, '')
        os, ver = /([a-zA-Z]+)(\d+)/.match(platform_path).captures
        puts "===================================="
        puts "Packaging for #{os} #{ver}"
        puts "===================================="
        stdout, stderr, exitstatus = Pkg::Util::Execution.capture3(%(bash controller.sh #{os} #{ver} #{staging_path}))
        Pkg::Util::Execution.success?(exitstatus) or raise "Error running packaging: #{stdout}\n#{stderr}"
        puts "#{stdout}\n#{stderr}"

        # carry forward defaults from mock.rake
        repo = Pkg::Config.yum_repo_name || 'products'
        platform_path = "#{os}/#{ver}/#{repo}/"

        # We want to include the arches for amazon/el/sles/fedora/redhatfips paths
        ['x86_64', 'i386'].each do |arch|
          target_dir = "#{pkg_path}/#{platform_path}#{arch}"
          FileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)
          FileUtils.cp(Dir.glob("*#{os}#{ver}*.rpm"), target_dir)
        end
      end
      Pkg::Config.cows.split(" ").each do |cow|
        # So you might think, from looking at
        # https://github.com/puppetlabs/packaging/blob/551be049ae0261f0dd1b632993d4fbe1ada63d9c/lib/packaging/deb/repo.rb#L72
        # that we want the repo to default to 'main' if unset. However, looking
        # deeper into that method we need repo to be '' if apt_repo_name is unset
        # https://github.com/puppetlabs/packaging/blob/551be049ae0261f0dd1b632993d4fbe1ada63d9c/lib/packaging/deb/repo.rb#L106
        repo = Pkg::Config.apt_repo_name || ''
        platform = cow.split('-')[1..-2].join('-')

        # get rid of the trailing slash if repo = ''
        platform_path = "deb/#{platform}/#{repo}".sub(/\/$/, '')

        FileUtils.mkdir_p("#{pkg_path}/#{platform_path}")
        # there's no differences in packaging for deb vs ubuntu so picking debian
        # if that changes we'll need to fix that
        puts "===================================="
        puts "Packaging for #{platform}"
        puts "===================================="
        stdout, stderr, exitstatus = Pkg::Util::Execution.capture3(%(bash controller.sh debian #{platform} #{staging_path}))
        Pkg::Util::Execution.success?(exitstatus) or raise "Error running packaging: #{stdout}\n#{stderr}"
        puts "#{stdout}\n#{stderr}"
        FileUtils.cp(Dir.glob("*#{platform}*.deb"), "#{pkg_path}/#{platform_path}")
      end
      FileUtils.cp_r(pkg_path, nested_output)
      FileUtils.rm_r(staging_path)
    end
  end

  desc "get the property and bundle artifacts ready"
  task :prep_artifacts, [:output_dir] => "pl:fetch" do |t, args|
    props = Pkg::Config.config_to_yaml
    bundle = Pkg::Util::Git.git_bundle('HEAD')
    FileUtils.cp(props, "#{args[:output_dir]}/BUILD_PROPERTIES")
    FileUtils.cp(bundle, "#{args[:output_dir]}/PROJECT_BUNDLE")
  end
end
