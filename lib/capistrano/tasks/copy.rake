require 'tempfile'

namespace :copy do
  staging_dir = File.join(Dir.tmpdir, release_timestamp)
  archive_name = File.join(Dir.tmpdir, (release_timestamp + '.tar.gz'))
  exclude_files  = fetch(:exclude_dir) || []
  tar_executable = fetch(:copy_local_tar) || "tar"
  tar_flags = fetch(:copy_local_tar_flags) || "-czf"
  tar_exclude_flags = ""
  exclude_files.each { |x| tar_exclude_flags += "--exclude=#{x} "}

  desc "Copy to staging area #{staging_dir}"
  file staging_dir do
    cp_r('.', staging_dir, :verbose => true)
  end 

  desc "Create tarball #{archive_name}"
  file archive_name => staging_dir do |t|
    sh "#{tar_executable} --directory=#{Dir.tmpdir} #{tar_flags} #{tar_exclude_flags.strip!} #{t.name} #{release_timestamp}"
  end

task :put_releases_path do
  puts releases_path
end

  task :ls_tarball => archive_name do |t|
    tarball = t.prerequisites.first
    run_locally do
      execute :ls, '-la', tarball
    end
  end


  desc "Deploy #{archive_name} to release_path"
  task :deploy => archive_name do |t|
    tarball = t.prerequisites.first
    on roles :all do

      upload_path = File.join(releases_path)

      upload!(tarball, upload_path)
      local_tarball_path = File.join(releases_path, File.basename(tarball))
      execute :tar, "-xzhf", local_tarball_path, "-C", releases_path
      execute :rm, local_tarball_path
    end

    Rake::Task["copy:clean"].invoke

  end

  task :clean do |t|
    # Delete the local archive
    rm_rf archive_name if File.exists? archive_name
    rm_rf staging_dir if File.directory? staging_dir
  end

  task :create_release => :deploy

  task :check

  task :set_current_revision

end