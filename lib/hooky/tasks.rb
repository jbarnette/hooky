git_hooks = %w(applypatch-msg commit-msg post-applypatch post-checkout
  post-commit post-merge pre-applypatch pre-auto-gc pre-commit
  pre-rebase prepare-commit-msg)

git_hook_files = git_hooks.collect { |f| ".git/hooks/#{f}" }

git_hook_files.each do |f|
  file f do |task|
    sh "ln -s hooky #{task.name}"
  end
end

desc "Install magical Rake Git hooks. Nondestructive."
task "hooky:install" => [".git/hooks/hooky", *git_hook_files]

file ".git/hooks/hooky" do |task|
  File.open task.name, "w" do |f|
    f.puts "#!/bin/sh"
    f.puts "export HOOK=$0"
    f.puts "export HOOK_ARGS=$@"
    f.puts "rake -s hooky"
  end

  sh "chmod +x #{task.name}"
end

# These tasks are intentionally not described in Rake's -T output to
# avoid clutter. The 'hooky' task dispatches to a specific hook
# task. To add behavior to a Git hook in your own Rakefile, 'redefine'
# the appropriate task.

task :hooky do
  ENV["HOOK"] && ENV["HOOK_ARGS"] or raise "Need HOOK and HOOK_ARGS."

  hook = File.basename ENV["HOOK"]
  args = ENV["HOOK_ARGS"].split /\s+/

  warn({ :hook => hook, :args => args }.inspect) if ENV["DEBUG"]
  Rake::Task["git:#{hook}"].invoke *args
end

task "git:applypatch-msg", [:file]

task "git:commit-msg", [:file]

task "git:post-applypatch"

task "git:post-checkout", [:old, :new, :branch] do |_, args|
  args.to_hash[:branch] = args[:branch] == "1"
end

task "git:post-commit"

task "git:post-merge", [:squash] do |_, args|
  args.to_hash[:squash] = args[:squash] == "1"
end

task "git:pre-applypatch"

task "git:pre-auto-gc"

task "git:pre-commit"

task "git:pre-rebase"

task "git:prepare-commit-msg", [:file, :source, :sha]
