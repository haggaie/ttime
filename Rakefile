require 'rake/rdoctask'
require 'fileutils'
require 'tempfile'

VERSION_FILE = "lib/ttime/version.rb"

def write_version_file(version)
  open(VERSION_FILE, "w") do |f|
    f.puts <<-EOF
# DO NOT EDIT
# This file is auto-generated by build scripts.
# See: with_version
module TTime
  Version = %q{#{version}}
end
    EOF
  end
end

Rake::RDocTask.new("doc") do |rdoc|
  rdoc.rdoc_dir = "doc"
  rdoc.title = "TTime -- A Technion Timetable utility"
  rdoc.main = "README.rdoc"
  rdoc.rdoc_files.include('README.rdoc')
  rdoc.rdoc_files.include('lib/**/*.rb')
end

desc "Update version number"
task :update_version do
  if `git status | grep -vE '^(#|nothing to commit)'` != ''
    $stderr.puts "fatal: Working copy unclean"
    system("git status")
    raise "fatal: Working copy unclean"
  end
  new_version = ENV['TTIME_VERSION'].dup
  raise "Usage: #{ARGV[0]} TTIME_VERSION=[version]" unless new_version
  new_version.sub!(/^v/,'')
  write_version_file(new_version)
  system "git add #{VERSION_FILE} && " \
         "git commit -m 'Update version number to #{new_version}' && " \
         "git tag v#{new_version}"
end

desc "Generate ditz html pages"
task :ditz_html do
  `ditz html ditz`
end

# Base path for SSH uploads (in scp syntax)
WebsiteSSHBasePath = "lutzky.net:public_html/ttime/"

desc "Upload documentation and ditz pages"
task :upload_html => [ :doc, :ditz_html ] do
  `rsync -r ditz doc #{WebsiteSSHBasePath}`
end

desc "Find all FIXME comments"
task :fixme do
  puts `grep -r FIXME * | grep -v '.git'`
end

desc "Create mo-files for L10n"
task :makemo do
  require 'gettext'
  require 'gettext/version'
  if GetText::VERSION >= "2.1.0"
    require 'gettext/tools'
    GetText.create_mofiles({:verbose => true,
                            :po_root => "po",
                            :targetdir => "data/locale"})
  else
    require 'gettext/utils'
    GetText.create_mofiles(true, "po", "data/locale")
  end
end

desc "Update pot/po files to match new version"
task :updatepo do
  require 'gettext/utils'
  GetText.update_pofiles("ttime",
                         Dir.glob("lib/**/*.rb") +
                         Dir.glob("data/ttime/*.ui") +
                         [ "bin/ttime" ],
                         "ttime 0.x.x")
end

desc "Zip up relevant windows package files (without Ruby)"
task :winbuild => [ :makemo ] do
  with_version do
    FileUtils::copy_file "debian/changelog", "./changelog"
    `zip -r ttime_win.zip ttime_win.bat bin data lib README.rdoc`
    File::unlink "changelog"
  end
end
