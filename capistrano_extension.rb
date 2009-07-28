# Uncomment this if you reference any of your controllers in activate
# require_dependency 'application'

class CapistranoExtension < Radiant::Extension
  version "1.0"
  description "Describe your extension here"
  url "http://yourwebsite.com/capistrano"
  
  # define_routes do |map|
  #   map.namespace :admin, :member => { :remove => :get } do |admin|
  #     admin.resources :capistrano
  #   end
  # end
  
  def activate
    # admin.tabs.add "Capistrano", "/admin/capistrano", :after => "Layouts", :visibility => [:all]
  end
  
  def deactivate
    # admin.tabs.remove "Capistrano"
  end
  
end
