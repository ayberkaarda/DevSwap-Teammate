require "test_helper"

# Bu makinede sistem genelinde Google Chrome kurulu olmayabilir (sadece Microsoft
# Edge bulunuyor). Edge, Chromium tabanlı olduğu için Selenium'un :chrome
# sürücüsüyle uyumludur; sadece binary yolunu Edge'e işaret etmemiz yeterli.
# Chrome varsa onu, yoksa Edge'i kullanır.
Capybara.register_driver :headless_chrome_or_edge do |app|
  chrome_paths = [
    "C:/Program Files/Google/Chrome/Application/chrome.exe",
    "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
    File.expand_path("~/AppData/Local/Google/Chrome/Application/chrome.exe")
  ]
  edge_paths = [
    "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
    "C:/Program Files/Microsoft/Edge/Application/msedge.exe"
  ]

  chrome_binary = chrome_paths.find { |p| File.exist?(p) }
  edge_binary = edge_paths.find { |p| File.exist?(p) }

  if chrome_binary
    options = Selenium::WebDriver::Options.chrome(
      args: %w[headless=new no-sandbox disable-gpu disable-dev-shm-usage window-size=1400,1400]
    )
    options.binary = chrome_binary
    Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
  else
    # Chrome bulunamadı, Chromium tabanlı Microsoft Edge'e düş (bu makinede kurulu).
    options = Selenium::WebDriver::Options.edge(
      args: %w[headless=new no-sandbox disable-gpu disable-dev-shm-usage window-size=1400,1400]
    )
    options.binary = edge_binary if edge_binary
    Capybara::Selenium::Driver.new(app, browser: :edge, options: options)
  end
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :headless_chrome_or_edge, screen_size: [ 1400, 1400 ]
end
