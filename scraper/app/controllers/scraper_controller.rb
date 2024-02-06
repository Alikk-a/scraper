class ScraperController < ApplicationController

  require 'selenium-webdriver'
  require 'nokogiri'
  require "httparty"
  require 'chronic_duration'

  before_action :set_logger

  def testing
    @list_link_jobs = []
    list_link_jobs = Linkedin.where('title IS ? And posted_at IS ?', nil, nil).order(:id)
    list_link_jobs.each do |job|
      @list_link_jobs << (job.linkedin_id_job + ' / ' + job.type_job + ' / ' + job.location)
    end
    @description = []
    render :list_jobs
  end

  def index

    @list_link_jobs = list_jobs('ruby on rails', 'China', 3)
    one_job

    @list_link_jobs = list_jobs('java', 'China', 3)
    one_job

    @list_link_jobs = list_jobs('python', 'China', 5)
    one_job

    if missed_jobs == Linkedin.where('title IS ? And posted_at IS ?', nil, nil).length > 0
      @custom_logger.info 'Dop pass 1.  Missed jobs in first pass: ' + missed_jobs.to_s
      one_job
    end

    if missed_jobs == Linkedin.where('title IS ? And posted_at IS ?', nil, nil).length > 0
      @custom_logger.info 'Dop pass 2.  Missed jobs in first pass: ' + missed_jobs.to_s
      one_job
    end

  end


  def one_job
    needed_pages = Linkedin.where('title IS ? And posted_at IS ?', nil, nil).order(:id)

    if needed_pages.length == 0
      @output = 'Nothing to scrap'
    end

    usa_array = ['Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36',
                 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36',
                 'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:40.0) Gecko/20100101 Firefox/40.0',
                 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/7.1.7 Safari/537.85.16',
                 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.152 Safari/537.36']

    needed_pages.each do |job|
      begin
        usa = usa_array[rand(usa_array.length)]
        @custom_logger.info 'User agent: ' + usa

        response = HTTParty.get(job.link_job, {headers: {'User-Agent': usa}, })

        page = Nokogiri::HTML(response)

        title_job = page.at_css('h1.top-card-layout__title').text
        posted_job = page.at_css('span.posted-time-ago__text').text.strip
        description = page.at_css('section div.show-more-less-html__markup')
        posted_date = parse_duration_to_datetime(posted_job)
        @custom_logger.info 'Title of Job: ' + title_job + ' | Job posted: ' + posted_date.to_s

        job.title = title_job
        job.description = description
        job.posted_at = posted_date

        if job.save
          @custom_logger.info 'Details of Job  №: ' + job.linkedin_id_job + ' successfully saved'
        end

      rescue HTTParty::Error => e
        # Handle HTTP errors (e.g., 404)
        @custom_logger.warn "HTTP Error: #{e.message} for #{job.linkedin_id_job}"

      rescue StandardError => e
        # Handle other types of errors
        @custom_logger.warn "Error: #{e.message} for #{job.linkedin_id_job}"
      end

      randon_sleep = rand(11) + 2
      sleep randon_sleep
    end

    # render :finish
  end

  def list_jobs(category = 'python', area = 'Germany', deep_page = 1)

    profile = Selenium::WebDriver::Firefox::Profile.from_name("default")
    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
    options.add_argument('--start-maximized')
    options.add_argument('--ignore-certificate-errors')
    options.add_argument('--disable-popup-blocking')
    options.add_argument('--disable-translate')

    wait = Selenium::WebDriver::Wait.new(timeout: 11)

    driver = Selenium::WebDriver.for :firefox, options: options
    driver.manage.window.resize_to(1910, 1039)
    driver.get 'https://www.linkedin.com/'

    @custom_logger.info '--------- Start with ' + category.upcase + ' in ' + area.upcase + '---------'

    # --------- go to Find_jobs page ----------
    sleep 2.seconds
    button_jobs = wait.until do
      driver.find_element(xpath: '//a[contains(@href,"/jobs/")]')
    end
    button_jobs.click

    # -------- set filter for category jobs ----------
    sleep 1
    search_input = wait.until do
      driver.find_element(xpath: "//*[contains(@id, 'jobs-search-box-keyword')]")
    end
    fill_form(search_input, category, true)

    # -------- set filter for category jobs ----------
    location = wait.until do
      driver.find_element(xpath: "//*[contains(@id, 'jobs-search-box-location')]")
    end
    sleep 2
    location.clear
    fill_form(location, area, true)

    # get first page ---------
    html_link_collection = list_one_page_jobs(driver, wait, 1)
    @list_link_jobs = check_and_save_links(html_link_collection, category, area)

    page = 2
    while page <= deep_page
      begin
        button_page = wait.until do
          driver.find_element(xpath: "//button[contains(@aria-label, 'Page #{page}')]")
        end
        button_page.click
      rescue StandardError => e
        # Handle other types of errors
        @custom_logger.warn "Error: #{e.message}"
        page = deep_page
      end

      sleep 3
      html_link_collection = list_one_page_jobs(driver, wait, page)
      @list_link_jobs = @list_link_jobs | check_and_save_links(html_link_collection, category, area)
      page += 1
    end
    @list_link_jobs
  end

  def list_one_page_jobs(driver, wait, page)
    jobs_per_page = 25

    sleep 3
    link_collection = get_list_jobs(driver, wait)
    # --------- go to last received job ----------
    driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection[-1])

    sleep 5
    link_collection = get_list_jobs(driver, wait)
    log_links(link_collection, '1', page)
    if link_collection.length > jobs_per_page - 1
      return link_collection
    end
    # --------- go to the bottom if got not all jobs ----------
    sleep 3

    # find buttons of pagination
    js_code = "window.element = document.getElementsByClassName('artdeco-pagination__indicator');"
    driver.execute_script(js_code)
    wait.until { driver.execute_script("return window.element !== undefined;") }
    scroll_down = driver.execute_script("return window.element;")

    # if no pagination - find block of feedback
    if scroll_down[0] == nil
      js_code = "window.element = document.getElementsByClassName('jobs-list-feedback--fixed-width');"
      driver.execute_script(js_code)
      wait.until { driver.execute_script("return window.element !== undefined;") }
      scroll_down = driver.execute_script("return window.element;")
    end

    driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", scroll_down[0])



    sleep 9
    link_collection_2 = get_list_jobs(driver, wait)
    log_links(link_collection_2, '2', page)
    link_collection = link_collection | link_collection_2
    if link_collection.length > jobs_per_page - 1
      return link_collection
    end

    # --------- go up if not all jobs yet ----------
    driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection_2[link_collection_2.length / 3])
    sleep 13
    link_collection_3 = get_list_jobs(driver, wait)
    log_links(link_collection_3, '3', page)
    link_collection = link_collection | link_collection_3
  end

  def check_and_save_links(object_links, category, area)
    list_link_jobs = []
    object_links.each_with_index do |obj, index|
      link = obj.attribute("href")
      @custom_logger.info (index + 1).to_s + ': ' + link.to_s.truncate(83)

      if link.include?('/jobs/view/') && !link.include?('alternate')
        list_link_jobs << link
        # job_id = link.match(/\/(\d+)\/?$/)[1]
        job_id = link.split('/')[5]
        if Linkedin.where(linkedin_id_job: job_id).empty?
          new_job = Linkedin.new
          new_job.link_job = link
          new_job.linkedin_id_job = job_id
          new_job.type_job = category
          new_job.location = area
          @custom_logger.info 'Saved: ' + job_id
          new_job.save
        end
      end
    end
    @custom_logger.info 'Amount links: ' + object_links.length.to_s
    list_link_jobs
  end

  def log_links(object_links, n_pass, page)
    object_links.each_with_index do |obj, index|
      link = obj.attribute("href")
      @custom_logger.info (index + 1).to_s + ': ' + link.to_s.truncate(83)
    end
    @custom_logger.info '--------------  Page: ' + page.to_s + ' Pass: ' + n_pass + ' amount of links: ' + object_links.length.to_s
  end

  def get_list_jobs(driver, wait)
    html_link_collection = wait.until do
      driver.find_elements(xpath: '//a[contains(@class,"job-card-list__title")]')
    end
    # ------ getting list using JS ----------------------
    # js_code_s = "window.el = document.getElementsByClassName('job-card-list__title'); console.log('Amount = '+Object.keys(el).length);"
    # driver.execute_script(js_code_s)
    # wait.until { driver.execute_script("return window.el !== undefined;") }
    # html_link_collection = driver.execute_script("return window.el;")
  end

  def fill_form(element, key_string, need_enter)
    key_string.split('').each do |l|
      element.send_keys l
      sleep 0.11
    end
    if need_enter
      sleep 1.seconds
      element.send_keys :enter
    end
  end

# Function to convert human-readable duration to datetime
  def parse_duration_to_datetime(duration_str)
    duration = ChronicDuration.parse(duration_str)
    current_datetime = Time.now
    past_datetime = current_datetime - duration
    past_datetime.strftime('%Y-%m-%d %H:%M')
  end

  private

  def set_logger
    @custom_logger = Logger.new("log/scraper_link.log")
    @custom_logger.datetime_format = "%Y-%m-%d %H:%M:%S"
  end

  def one_job_selenium
    require 'selenium-webdriver'

    user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 uacq;'
    args = ['--start-maximized', 'ignore-certificate-errors', 'disable-popup-blocking', 'disable-translate']
    options = Selenium::WebDriver::Chrome::Options.new(args: args)
    options.add_argument("--user-agent=#{user_agent}")
    # Adding argument to disable the AutomationControlled flag
    options.add_argument("--disable-blink-features=AutomationControlled")

    driver = Selenium::WebDriver.for :chrome, options: options

    wait = Selenium::WebDriver::Wait.new(timeout: 5)
    # driver.manage.window.maximize

    driver.get 'https://www.linkedin.com/login/ru?fromSignIn=true&trk=guest_homepage-basic_nav-header-signin'

    user = wait.until do # Wait was defined in the initalize method of the main class, if it takes more than 10s to find the element, something went wrong
      driver.find_element(id: 'username')
    end
    sleep 2.seconds
    'petrokutcenco@mail.ru'.split('').each do |l|
      user.send_keys l
      sleep 0.13
    end
    user.send_keys :enter
    sleep 2.seconds

    pass = driver.find_element(id: 'password')
    'admin958'.split('').each do |l|
      pass.send_keys l
      sleep 0.11
    end
    sleep 1.seconds
    button_login = driver.find_element(:class, 'btn__primary--large')
    button_login.click


    list_jobs = ['https://www.linkedin.com/jobs/view/3809343821/?eBP=CwEAAAGNHeB8t0q1qS9AQnuI7HZ6macryT9palX1U5FKBt1Vaf9C8w1P47RtKm-IRTHwTbmU5Lo-Z81Dm-xrj-kvELmU166573m9_7fkK-pnEuk23KmdGjWVLzoTGvfQuenLaZHIGaTwUXt9AmJCiZhoEvx5yWpKvqmhlVU_UMBTcBMFt4VXrRwxXrODHF_raztm5w8W8JsjsyYZrwIVYBKUzPfwSfRNr4HW1kTOmqNxQ58vBubqSQ6CJrbSJtiIA1v_bSxSWSpbPFgP1VJrEMya-2JkTdL-h1TlC1xppsBiJ8wWFh46RhBeZy0e5hDgym331lRen69135I6vav0HH2Uvm9x4N3498RMowcuuD7cYb19qdEHMJ5e1FTvBfbo-OW3MYzOU90IlW4cYIthzb0Yehqgnw&refId=iYlSkRpDlU7HJil0VRzRrg%3D%3D&trackingId=b4rh7fs17aV9F82jX%2FoonA%3D%3D&trk=flagship3_search_srp_jobs',
                 'https://www.linkedin.com/jobs/view/3804530982/?eBP=CwEAAAGNHeB4BwxjGlVKDsZCEFLyY1vUXXNVq6g-aYBOyVTqh0jdq4bnQQQuQ3rUFr5KaaeqdPDGUoO09ND3CH5DXsg4h3GBL_hrT2iHno4JyH0STNabQxb1T1YOVFHzzRUrGVXMV7BfNiBH01DsibyKzT33NmwLz6DiIq_WtsnDfrdrLFftTVp7bKL_mS-JQB8ZBtGqyozQCJfYUbMUFopX9bg_iYnTVf7yAOR30vKRfn-yCUtioaKmfhT4Vzlv1qCtGAqrz2LrjuOC-q466zezCU2c6318_8N48VzkCc9A9aqH4f17TOjo8zG_aJ78NKvFn1aF4oIHo5jF8sE9W3Q2EYlxIgcESnofOZE9PUG5IHZMiSJSbrlIjj5oKesP2ORqISdgU7Y4X3kU1x3Z73gS9k542wnD&refId=Wbo4RiXZxR78p%2FTdWbGOag%3D%3D&trackingId=xQl%2Fup25Gci1F15VHDbkFg%3D%3D&trk=flagship3_search_srp_jobs',
                 'https://www.linkedin.com/jobs/view/3808538044/?eBP=CwEAAAGNHeBzCiBCJGLIq_GpXlHFUqUpLBiuYX7186te2-DyeHsbvt5vflG3Lpu1Te9syUb6fEwyCap7paNS3-5UMHFh5XNKdf8gQDB-8SuNJEFS0tO5oAT_2yT8K_G7ACwug5taCdOYtRH1tJ0XJnce3NG3JTILXVbmRpuqcTYYzR0-0R-zhnMa9a7LXe0GKGVRl9ga4G8x1FArT_vZ-899PbQcVRiikUJnHFzO2hCsJvy5iSd5RY8AxOn04W7Liql09d20EBGVlAW1Gc0uqHl0AC4LgnBGvxDZTZUFekBa8xKhX4gzOr_neEGidjmro_xqTr5_UHJ3cwkvqa97tOBGPF6Bkmo1yMDJ7HLh0OjloZN4f7kcbtY4utzND913Lb4i5gJ82u4y8xCdUyohzXO-dfl2YhJGyxQ&refId=Wbo4RiXZxR78p%2FTdWbGOag%3D%3D&trackingId=kcd40GCHkgpQ4P7TWIsI%2Bw%3D%3D&trk=flagship3_search_srp_jobs']

    sleep 3.seconds

    @title = []
    @description = []

    list_jobs.each do |job|
      driver.get job
      sleep 2
      title = wait.until do
        driver.find_element(class: 'job-details-jobs-unified-top-card__job-title').text
      end
      @title << title

      description = wait.until do
        driver.find_element(id: 'job-details').attribute("innerHTML").to_s
      end
      @description << description
    end

    render :index

  end

  def list_jobs_chrome
    require 'selenium-webdriver'

    # user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 uacq;'
    user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36;'
    args = ['--start-maximized', 'ignore-certificate-errors', 'disable-popup-blocking', 'disable-translate']
    options = Selenium::WebDriver::Chrome::Options.new(args: args)
    options.add_argument("--user-agent=#{user_agent}")
    # Adding argument to disable the AutomationControlled flag
    options.add_argument("--disable-blink-features=AutomationControlled")

    driver = Selenium::WebDriver.for :chrome, options: options

    wait = Selenium::WebDriver::Wait.new(timeout: 5)

    driver.get 'https://www.linkedin.com/'

    if File.exist?('cookies.txt')
      cookies = JSON.parse(File.read('cookies.txt'))
      cookies.each do |cookie_hash|
        if cookie_hash['expires']
          expiry_time = Time.parse(cookie_hash['expires'])
          cookie_hash['expires'] = expiry_time.to_i
        end

        driver.manage.add_cookie(
            name: cookie_hash['name'],
            value: cookie_hash['value'],
            path: cookie_hash['path'],
            domain: cookie_hash['domain'],
            secure: cookie_hash['secure'],
            expires: cookie_hash['expires'],
            same_site: cookie_hash['same_site'],
            http_only: cookie_hash['http_only']
        )
      end
    end

    sleep 3
    driver.get 'https://www.linkedin.com/'

    sleep 2.seconds
    button_jobs = wait.until do
      driver.find_element(xpath: '//a[contains(@href,"/jobs/")]')
    end
    button_jobs.click

    sleep 1.seconds
    location = wait.until do
      driver.find_element(xpath: "//*[contains(@id, 'jobs-search-box-location-id')]")
    end
    # location.clear
    'Germany'.split('').each do |l|
      location.send_keys l
      sleep 0.11
    end
    sleep 0.21
    # location.send_keys :enter

    sleep 1.seconds
    search_input = driver.find_element(xpath: "//*[contains(@id, 'jobs-search-box-keyword-id')]")
    'ruby'.split('').each do |l|
      search_input.send_keys l
      sleep 0.11
    end
    sleep 1.seconds
    search_input.send_keys :enter

    sleep 2.seconds
    @list_link_jobs = []
    list_jobs = wait.until do
      # driver.find_element(class: 'scaffold-layout__list')
      driver.find_elements(xpath: '//a[contains(@id,"ember")]')
    end


    list_jobs.each do |obj|
      sleep 1
      link = obj.attribute("href").to_s
      @list_link_jobs << link
    end

    # sleep 1.seconds
    # modal_close = wait.until do
    #   driver.find_elements(:class, 'cta-modal__dismiss-btn')
    # end
    # if modal_close
    #   if modal_close[1]
    #     modal_close[1].click
    #     sleep 1
    #     modal_close[0].click
    #   else
    #     modal_close[0].click
    #   end
    # end

  end

  def set_authorization
    require 'selenium-webdriver'
    require 'json'

    # user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/111.0.0.0 Safari/537.36 uacq;'
    user_agent = 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36;'
    args = ['--start-maximized', 'ignore-certificate-errors', 'disable-popup-blocking', 'disable-translate']
    options = Selenium::WebDriver::Chrome::Options.new(args: args)
    options.add_argument("--user-agent=#{user_agent}")
    # Adding argument to disable the AutomationControlled flag
    options.add_argument("--disable-blink-features=AutomationControlled")

    driver = Selenium::WebDriver.for :chrome, options: options

    wait = Selenium::WebDriver::Wait.new(timeout: 5)

    #--- authorization ----------------
    driver.get 'https://www.linkedin.com/login/ru?fromSignIn=true&trk=guest_homepage-basic_nav-header-signin'

    user = wait.until do # Wait was defined in the initalize method of the main class, if it takes more than 10s to find the element, something went wrong
      driver.find_element(id: 'username')
    end
    sleep 1.seconds
    user.send_keys 'petrokutcenco@mail.ru'
    sleep 0.5
    user.send_keys :enter

    sleep 0.5.seconds
    pass = driver.find_element(id: 'password')
    'admin958'.split('').each do |l|
      pass.send_keys l
      sleep 0.11
    end
    sleep 1.seconds
    button_login = driver.find_element(class: 'btn__primary--large')
    button_login.click
    #--- END authorization ----------------
    cookies = driver.manage.all_cookies
    File.open('cookies.txt', 'w') { |file| file.puts(cookies.to_json) }

    driver.get("http://tarunlalwani.com")

    @list_link_jobs = ['Cookies SETTED']
    render :list_jobs
  end

end

