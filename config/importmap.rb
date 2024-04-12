# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/turbo-rails", to: "turbo.min.js", preload: true
pin "@hotwired/stimulus", to: "@hotwired--stimulus.js" # @3.2.2
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin "@hotwired/strada", to: "@hotwired--strada.js" # @1.0.0
pin_all_from "app/javascript/controllers", under: "controllers"
