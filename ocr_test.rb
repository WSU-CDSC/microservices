#!/usr/bin/env ruby

require 'pdf-reader'

# Find PDF Inputs
pdf_files = []
ARGV.each do |target|
  if File.directory?(target)
    files = Dir.glob("#{target}/**/*.pdf")
    files.each { |pdf| pdf_files << pdf }
  else
    if File.extname(target) == '.pdf'
      pdf_files << target
    end
  end
end

pdf_files.each do |file|
  pdf_text = []
  pdf_data = PDF::Reader.new(file)
  # pdf_text << pdf_data.page(1).text
  pdf_data.pages.each do |page|
    pdf_text << page.text
  end
  if pdf_text.to_s.length > 50
    puts "TEXT FOUND!"
  else
    puts "NO TEXT!"
  end
end
