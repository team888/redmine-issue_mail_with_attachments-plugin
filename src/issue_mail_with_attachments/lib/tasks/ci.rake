unless Rails.env.production?
    require 'coveralls/rake/task'
    Coveralls::RakeTask.new
end