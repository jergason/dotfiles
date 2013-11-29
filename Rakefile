task :default => [:install_vim, :install_dotfiles]

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


desc "Install gocode for golang code completion"
task :install_gocode do
  `go get -u github.com/nsf/gocode`
end

desc "Install .vim directory by pulling them from my githubs."
task :install_vim do
  `rm -rf #{vim_dir}`
  `mkdir -p #{File.join(vim_dir, 'tmp')}` # for tmp and swap files
  Rake::Task[:install_vundle].invoke
end

desc "Install vundle"
task :install_vundle do
  puts "installing vundle"
  `mkdir -p #{File.join(vim_dir, 'bundle')}`
  `git clone git@github.com:gmarik/vundle.git #{File.join(vim_dir, 'bundle', 'vundle')}`
  `vim +BundleInstall +qall`
end

def vim_dir
  vim_dir = File.expand_path(File.join(File.dirname(__FILE__), '.vim'))
end
