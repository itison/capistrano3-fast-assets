namespace :load do
  task :defaults do
    set :asset_manifest_path, "config/manifest.yml"
    set :asset_locations, ["app/assets", "lib/assets", "vendor/assets", "Gemfile.lock"]
    set :asset_compiler_role, :app
    set :rails_env, fetch(:rails_env) || fetch(:stage)
  end
end

namespace :fast_assets do

  def compile_assets?
    force_compile = !!ENV["FORCE_COMPILE"]
    compile = true
    changed_assets = 0

    on primary(fetch(:asset_compiler_role)) do
      within repo_path do
        changes = capture(:git, "diff --numstat #{fetch(:current_revision)} #{fetch(:previous_revision)}")+" "
        changed_assets = fetch(:asset_locations).inject(0) do |sum, matcher| 
          sum + (changes.split(matcher).length - 1)
        end
        compile = !changed_assets.zero?
      end
      info "Asset compiling: (force=#{force_compile} && visible_change=#{changed_assets}) => Will compile? #{compile}"
    end

    compile || force_compile
  end

  desc "Compile Rails assets on :app_compiler if a change has been detected"
  task :compile do
    should_compile_assets = compile_assets? # Cap freezes if you call this from inside a role block

    on roles fetch(:asset_compiler_role) do
      within release_path do
        with rails_env: fetch(:rails_env) do
          if should_compile_assets
            execute :rake, "assets:precompile"
          else
            execute :cp,  [File.join(current_path, fetch(:asset_manifest_path)),
                           File.join(release_path, fetch(:asset_manifest_path))].join(" ")
          end
        end
      end
    end
  end

  desc "Share the asset manifest from the :app_compiler out to other servers"
  task :share_assets_manifest do
    Dir.mktmpdir do |tmp_dir|
      remote_manifest_path = File.join(release_path, fetch(:asset_manifest_path))
      local_manifest_path = File.join tmp_dir, 'manifest.yml'

      on primary fetch(:asset_compiler_role) do
        manifest_content = download!(remote_manifest_path)
        File.write local_manifest_path, manifest_content
      end

      on roles :all do
        upload! local_manifest_path, remote_manifest_path 
      end
    end
  end

  after 'deploy:updated', 'fast_assets:compile'
  after "fast_assets:compile", "fast_assets:share_assets_manifest"
end
