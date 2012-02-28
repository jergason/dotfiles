require 'yaml'

task :default => [:install_vim, :install_dotfiles]

desc "Install vim and dotfiles"
task :install => [:install_vim_plugins, :install_dotfiles]

desc "Make symlinks from all dotfiles in this directory to ~"
task :install_dotfiles do
  puts "installing dotfiles"
  files = Dir.entries('.')
  files.delete("..")
  files.delete(".")
  result = true
  files.each do |f|
    # The range syntax is to make it work with Ruby 1.8
    next if f[0...1] != '.' or f == '.git'
    #move the file over if it already exists
    if system("file ~/#{f}")
      system("mv ~/#{f} ~/old#{f}")
    end
    result = result & system("ln -s #{File.expand_path(f)} ~/#{f}")
  end
  if result
    puts "Worked"
  else
    puts "Oops, an error occurred"
  end
end



desc "Install .vim directory by pulling them from my githubs."
task :install_vim do
  `rm -rf #{vim_dir}`
  `mkdir -p #{File.join(vim_dir, 'tmp')}`

  Rake::Task[:install_pathogen].invoke
  `mkdir -p #{File.join(vim_dir, 'bundle')}`
  plugin_list = YAML::load(File.open('plugins.yaml'))
  plugin_list["git"].each do |name, git_url|
    install_plugin(git_url, name)
  end
end

desc "Install pathogen"
task :install_pathogen do
  puts "installing pathogen"
  `mkdir -p #{File.join(vim_dir, 'autoload')}`
  `curl -so #{File.join(vim_dir, 'autoload', 'pathogen.vim')} https://raw.github.com/tpope/vim-pathogen/HEAD/autoload/pathogen.vim`
end

def install_plugin(github_url, plugin_name)
  `git clone #{github_url} #{File.join(vim_dir, 'bundle', plugin_name)}`
end

def vim_dir
  vim_dir = File.expand_path(File.join(File.dirname(__FILE__), '.vim'))
end
