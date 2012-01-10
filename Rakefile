require 'rake/testtask'

Rake::TestTask.new do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :unicode => ["UnicodeData.txt"] do |t|
  require 'csv'
  rbfile = File.new(File.join(File.dirname(__FILE__), *%w[lib layo unicode.rb]), 'w')
  rbfile.puts('module Layo')
  rbfile.puts('  class Unicode')
  rbfile.puts('    DATA = {')
  CSV.foreach("UnicodeData.txt", { col_sep: ';' }) do |row|
    if row[1][0] != '<'
      rbfile.puts("      '#{row[1]}' => #{row[0].to_i(16)},")
    end
  end
  rbfile.puts('    }')
  rbfile.puts('  end')
  rbfile.puts('end')
end
