Shoes.app do
  test = button "Click here!"
  test.click do
    target = ask_open_folder 
    system('ruby','./scripts/make-csv.rb',target)
  end  
end
