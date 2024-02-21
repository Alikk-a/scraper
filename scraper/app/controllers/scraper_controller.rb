class ScraperController < ApplicationController

  require 'selenium-webdriver'
  require 'nokogiri'
  require "httparty"
  require 'chronic_duration'

  before_action :set_logger

  def testing(deep_page = 1)

    profile = Selenium::WebDriver::Firefox::Profile.from_name("default")
    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
    options.add_argument('--start-maximized')
    options.add_argument('--ignore-certificate-errors')
    options.add_argument('--disable-popup-blocking')
    options.add_argument('--disable-translate')

    wait = Selenium::WebDriver::Wait.new(timeout: 11)

    driver = Selenium::WebDriver.for :firefox, options: options
    driver.manage.window.resize_to(1910, 1039)

    link = 'https://www.linkedin.com/search/results/people/?keywords='
    search = 'it recruiter&page='
    get_page = '35'


    begin
      driver.get link + search + get_page
      @custom_logger.info "--------- Start GET contact with #{search} ---------"
    rescue HTTParty::Error => e
      @custom_logger.warn "HTTP Error: #{e.message}"
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

    begin
      list_one_page_contacts(driver, wait, 1)
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

    # get all next pages ---------
    page = 2
    while page <= deep_page
      begin
        button_page = wait.until do
          driver.find_element(xpath: "//button[contains(@aria-label, 'Page #{page}')]")
        end
        button_page.click
      rescue StandardError => e
        @custom_logger.warn "Error: #{e.message}"
        page = deep_page
      end

      sleep 3
      list_one_page_contacts(driver, wait, page)
      page += 1
    end

    render :finish
    # @list_link_jobs = []
    # list_link_jobs = get_unfilled_people.order(:id)
    # list_link_jobs.each do |job|
    #   @list_link_jobs << (job.id.to_s + ' / ' + job.id_person + ' / ' + job.search_by)
    # end
    # @description = []
    # render :list_jobs
  end

  def list_one_page_contacts(driver, wait, page)
    sleep 3
    begin
      # scroll to block of pagination
      js_code = "window.element = document.getElementsByClassName('artdeco-pagination__indicator');"
      driver.execute_script(js_code)
      wait.until { driver.execute_script("return window.element !== undefined;") }
      scroll_down = driver.execute_script("return window.element;")
      # driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", scroll_down[0])

      sleep 3
      link_collection = wait.until do
        # driver.find_elements(xpath: "//button[contains(@aria-label, 'Invite Julia Yachmen to connect')]")
        driver.find_elements(:xpath, "//button[contains(@aria-label, 'Invite') and contains(@aria-label, 'connect')]")
      end
      @custom_logger.info link_collection.to_s
      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection[0])
      link_collection[0].click

    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end
    # sleep 9
    # link_collection_2 = get_list_companies(driver, wait)
    # log_links(link_collection_2, '2', page)
    # link_collection = link_collection | link_collection_2
    # if link_collection.length > items_per_page - 1
    #   return link_collection
    # end
  end


  # ---------  GET People ------------------------------------------------

  def people
    threads = []

    threads << Thread.new do
      search = 'data scientist'

      link = 'https://www.linkedin.com/search/results/people/?geoUrn=%5B%22101282230%22%5D'
      list_people(link, search, 3)

      # sleep 5

    end

    sleep 130
    empty_attempts = 0
    while empty_attempts < 11
      if get_unfilled_people.length > 0
        @logger_one_job.info '**********************  Pass with: ' + get_unfilled_people.length.to_s + ' jobs to get *****************'
        # threads << Thread.new do
        one_person
        # end
        empty_attempts = 0
      else
        empty_attempts += 1
        sleep 3
      end
    end
    @logger_one_job.info '**********************  FINISH *****************'

    threads.each(&:join)

    render :finish
  end

  def one_person
    needed_pages = get_unfilled_people.order(:id)

    usa_array = ['Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/112.0.0.0 Safari/537.36',
                 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/45.0.2454.85 Safari/537.36',
                 'Mozilla/5.0 (Windows NT 10.0; WOW64; rv:40.0) Gecko/20100101 Firefox/40.0',
                 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_5) AppleWebKit/600.7.12 (KHTML, like Gecko) Version/7.1.7 Safari/537.85.16',
                 'Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.152 Safari/537.36',
                 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.2.1 Safari/605.1.1',
                 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 Edg/120.0.0',
                 'Mozilla/5.0 (Windows NT 10.0; WOW64; Trident/7.0; rv:11.0) like Geck',
                 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36 OPR/106.0.0',
                 'Mozilla/5.0 (Windows NT 10.0; Win64; x64; rv:109.0) Gecko/20100101 Firefox/115',
                 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/107.0.0.0 Safari/537.36 Edg/107.0.1418.2']

    needed_pages.each do |job|
      begin
        usa = usa_array[rand(usa_array.length)]
        @logger_one_job.info 'User agent: ' + usa

        link = job.link_person.to_s
        response = HTTParty.get(link, {headers: {'User-Agent': usa}, })

        page = Nokogiri::HTML(response)
        # @logger_one_job.info page.to_s

        name = page.at_css('h1.top-card-layout__title').nil? ? nil : page.at_css('h1.top-card-layout__title').text.strip
        subtitle = page.at_css('h2.top-card-layout__headline').nil? ? '' : page.at_css('h2.top-card-layout__first-subline').text.strip

        location_div = page.at_xpath("//div[@class='profile-info-subheader']")
        if location_div.nil?
          location = ''
        else
          location = location_div.at_css("span").text.strip
        end

        description = page.at_css('div.core-section-container__content')

        job.name = name
        job.subtitle = subtitle
        job.location = location
        job.description = description
        job.attempts = job.attempts + 1

        if job.save
          @logger_one_job.info 'location: ' + job.location + ' | ' + job.id_person + ' | searched_by: ' + job.search_by + ' : successfully saved'
        end

      rescue HTTParty::Error => e
        # Handle HTTP errors (e.g., 404)
        @logger_one_job.warn "HTTP Error: #{e.message} for #{job.id_person}"
        job.attempts = job.attempts + 1
        job.save
      rescue StandardError => e
        # Handle other types of errors
        @logger_one_job.warn "Error: #{e.message} for #{job.id_person}"
        job.attempts = job.attempts + 1
        job.save
      end

      randon_sleep = rand(11) + 2
      sleep randon_sleep
    end

    render :finish
  end

  def list_people(link, search, deep_page = 1)

    profile = Selenium::WebDriver::Firefox::Profile.from_name("default")
    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
    options.add_argument('--start-maximized')
    options.add_argument('--ignore-certificate-errors')
    options.add_argument('--disable-popup-blocking')
    options.add_argument('--disable-translate')

    wait = Selenium::WebDriver::Wait.new(timeout: 11)

    driver = Selenium::WebDriver.for :firefox, options: options
    driver.manage.window.resize_to(1910, 1039)

    begin
      driver.get link + '&keywords=' + search
      @custom_logger.info "--------- Start #{search} ---------"
    rescue HTTParty::Error => e
      @custom_logger.warn "HTTP Error: #{e.message}"
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

    begin
      # get first page ---------
      html_link_collection = list_one_page_people(driver, wait, 1)
      @list_link_jobs = check_and_save_people(html_link_collection, search)
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

    # get all next pages ---------
    page = 2
    while page <= deep_page
      begin
        button_page = wait.until do
          driver.find_element(xpath: "//button[contains(@aria-label, 'Page #{page}')]")
        end
        button_page.click
      rescue StandardError => e
        @custom_logger.warn "Error: #{e.message}"
        page = deep_page
      end

      sleep 3
      html_link_collection = list_one_page_people(driver, wait, page)
      @list_link_jobs = @list_link_jobs | check_and_save_people(html_link_collection, search)
      page += 1
    end
    @list_link_jobs
  end

  def list_one_page_people(driver, wait, page)
    items_per_page = 10
    begin
      sleep 3
      link_collection = get_list_people(driver, wait)
      # --------- go to last received job ----------
      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection[-1])

      sleep 5
      link_collection = get_list_people(driver, wait)
      log_links(link_collection, '1', page)
      if link_collection.length > items_per_page - 1
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
        js_code = "window.element = document.getElementsByClassName('reusable-search__entity-result-list');"
        driver.execute_script(js_code)
        wait.until { driver.execute_script("return window.element !== undefined;") }
        scroll_down = driver.execute_script("return window.element;")
      end

      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", scroll_down[0])

      sleep 9
      link_collection_2 = get_list_companies(driver, wait)
      log_links(link_collection_2, '2', page)
      link_collection = link_collection | link_collection_2
      if link_collection.length > items_per_page - 1
        return link_collection
      end

      link_collection

    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

  end

  def get_list_people(driver, wait)
    begin
      html_link_collection = wait.until do
        driver.find_elements(xpath: '//span[contains(@class,"entity-result__title-line")]/span/a')
      end
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end
  end

  def check_and_save_people(object_links, search)
    list_link_people = []
    object_links.each_with_index do |obj, index|
      begin
        link = obj.attribute("href").split('?')[0]
        @custom_logger.info (index + 1).to_s + ': ' + link.to_s.truncate(83)

        if link.include?('/in/')
          list_link_people << link
          id_person = link.split('/')[4]
          if LinkedinPerson.where(id_person: id_person).empty?
            new_person = LinkedinPerson.new
            new_person.link_person = link
            new_person.id_person = id_person
            new_person.search_by = search
            new_person.save
            @custom_logger.info 'Saved: ' + id_person
          else
            @custom_logger.info 'Person: ' + id_person + ' already exist in DB'
          end
        end
      rescue StandardError => e
        @custom_logger.warn "Error: #{e.message}"
      end
    end
    @custom_logger.info 'Amount links: ' + object_links.length.to_s
    list_link_people
  end


  # ---------  GET Companies ------------------------------------------------

  def companies
    threads = []

    threads << Thread.new do
      # search = 'cyber security'
      search = 'machine learning'

      link = 'https://www.linkedin.com/search/results/companies/?companyHqGeo=%5B%22101452733%22%5D'
      list_companies(link, search, 1)

      # sleep 5
      #
      # link = 'https://www.linkedin.com/search/results/companies/?companyHqGeo=%5B%22102478259%22%5D'
      # list_companies(link, search, 3)

      # sleep 7
      #
      # link = 'https://www.linkedin.com/search/results/companies/?companyHqGeo=%5B%22101452733%22%5D'
      # list_companies(link, search, 3)
    end

    sleep 130
    empty_attempts = 0
    while empty_attempts < 11
      if get_unfilled_companies.length > 0
        @logger_one_job.info '**********************  Pass with: ' + get_unfilled_companies.length.to_s + ' jobs to get *****************'
        # threads << Thread.new do
        one_company
        # end
        empty_attempts = 0
      else
        empty_attempts += 1
        sleep 3
      end
    end
    @logger_one_job.info '**********************  FINISH *****************'

    threads.each(&:join)

    render :finish
  end

  def one_company
    needed_pages = get_unfilled_companies.order(:id)

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
        @logger_one_job.info 'User agent: ' + usa

        link = job.link_company.to_s
        response = HTTParty.get(link, {headers: {'User-Agent': usa}, })

        page = Nokogiri::HTML(response)
        # @logger_one_job.info page.to_s

        title_company = page.at_css('h1.top-card-layout__title').nil? ? '' : page.at_css('h1.top-card-layout__title').text.strip
        website = page.at_xpath("//a[@data-tracking-control-name='about_website']").nil? ? '' : page.at_xpath("//a[@data-tracking-control-name='about_website']").text.strip

        headquarter_div = page.at_xpath("//div[@data-test-id='about-us__headquarters']")
        if headquarter_div.nil?
          headquarter = ''
        else
          headquarter = headquarter_div.css(".text-color-text").size >= 2 ? headquarter_div.css(".text-color-text")[1].text.strip : ''
        end

        size_div = page.at_xpath("//div[@data-test-id='about-us__size']")
        if size_div.nil?
          size = ''
        else
          size = size_div.css(".text-color-text").size >= 2 ? size_div.css(".text-color-text")[1].text.strip : ''
        end

        founded_div = page.at_xpath("//div[@data-test-id='about-us__foundedOn']")
        if founded_div.nil?
          founded = ''
        else
          founded = founded_div.css(".text-color-text").size >= 2 ? founded_div.css(".text-color-text")[1].text.strip : ''
        end

        company_type_div = page.at_xpath("//div[@data-test-id='about-us__organizationType']")

        if company_type_div.nil?
          company_type = ''
        else
          company_type = company_type_div.css(".text-color-text").size >= 2 ? company_type_div.css(".text-color-text")[1].text.strip : ''
        end

        description = page.at_css('div.core-section-container__content p.break-words')

        job.name = title_company
        job.website = website
        job.headquarters = headquarter
        job.number_employees = size
        job.founded = founded
        job.company_type = company_type
        job.description = description
        job.attempts = job.attempts + 1

        if job.save
          @logger_one_job.info job.name + ' | ' + job.id_company + ' | searched_by: ' + job.search_by + ' : successfully saved'
        end

      rescue HTTParty::Error => e
        # Handle HTTP errors (e.g., 404)
        @logger_one_job.warn "HTTP Error: #{e.message} for #{job.id_company}"
        job.attempts = job.attempts + 1
        job.save
      rescue StandardError => e
        # Handle other types of errors
        @logger_one_job.warn "Error: #{e.message} for #{job.id_company}"
        job.attempts = job.attempts + 1
        job.save
      end

      randon_sleep = rand(11) + 2
      sleep randon_sleep
    end

    render :finish
  end

  def list_companies(link, search, deep_page = 1)

    profile = Selenium::WebDriver::Firefox::Profile.from_name("default")
    options = Selenium::WebDriver::Firefox::Options.new(profile: profile)
    options.add_argument('--start-maximized')
    options.add_argument('--ignore-certificate-errors')
    options.add_argument('--disable-popup-blocking')
    options.add_argument('--disable-translate')

    wait = Selenium::WebDriver::Wait.new(timeout: 11)

    driver = Selenium::WebDriver.for :firefox, options: options
    driver.manage.window.resize_to(1910, 1039)

    begin
      driver.get link + '&keywords=' + search
      @custom_logger.info '--------- Start cyber security ---------'
    rescue HTTParty::Error => e
      @custom_logger.warn "HTTP Error: #{e.message}"
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

    begin
      # get first page ---------
      html_link_collection = list_one_page_companies(driver, wait, 1)
      @list_link_jobs = check_and_save_companies(html_link_collection, search)
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

    # get all next pages ---------
    page = 2
    while page <= deep_page
      begin
        button_page = wait.until do
          driver.find_element(xpath: "//button[contains(@aria-label, 'Page #{page}')]")
        end
        button_page.click
      rescue StandardError => e
        @custom_logger.warn "Error: #{e.message}"
        page = deep_page
      end

      sleep 3
      html_link_collection = list_one_page_companies(driver, wait, page)
      @list_link_jobs = @list_link_jobs | check_and_save_companies(html_link_collection, search)
      page += 1
    end
    @list_link_jobs
  end

  def list_one_page_companies(driver, wait, page)
    jobs_per_page = 10
    begin
      sleep 3
      link_collection = get_list_companies(driver, wait)
      # --------- go to last received job ----------
      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection[-1])

      sleep 5
      link_collection = get_list_companies(driver, wait)
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
        js_code = "window.element = document.getElementsByClassName('reusable-search__entity-result-list');"
        driver.execute_script(js_code)
        wait.until { driver.execute_script("return window.element !== undefined;") }
        scroll_down = driver.execute_script("return window.element;")
      end

      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", scroll_down[0])

      sleep 9
      link_collection_2 = get_list_companies(driver, wait)
      log_links(link_collection_2, '2', page)
      link_collection = link_collection | link_collection_2
      if link_collection.length > jobs_per_page - 1
        return link_collection
      end

      link_collection

    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end

  end

  def get_list_companies(driver, wait)
    begin
      html_link_collection = wait.until do
        driver.find_elements(xpath: '//span[contains(@class,"entity-result__title-line")]/span/a')
      end
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
    end
  end

  def check_and_save_companies(object_links, search)
    list_link_companies = []
    object_links.each_with_index do |obj, index|
      begin
        link = obj.attribute("href")
        @custom_logger.info (index + 1).to_s + ': ' + link.to_s.truncate(83)

        if link.include?('/company/')
          list_link_companies << link
          company_id = link.split('/')[4]
          if LinkedinCompany.where(id_company: company_id).empty?
            new_company = LinkedinCompany.new
            new_company.link_company = link
            new_company.id_company = company_id
            new_company.search_by = search
            @custom_logger.info 'Saved: ' + company_id
            new_company.save
          else
            @custom_logger.info 'Company: ' + company_id + ' already exist in DB'
          end
        end
      rescue StandardError => e
        @custom_logger.warn "Error: #{e.message}"
      end
    end
    @custom_logger.info 'Amount links: ' + object_links.length.to_s
    list_link_companies
  end

  # ---------  END Companies ------------------------------------------------


  def index

    threads = []

    threads << Thread.new do
      # list_jobs('ruby on rails', 'Belgium', 1)
      # sleep 5
      list_jobs('C#', 'Norway', 3)
      # sleep 5
      # list_jobs('ruby on rails', 'Germany', 2)
    end

    sleep 130
    empty_attempts = 0
    while empty_attempts < 11
      if get_unfilled_jobs.length > 0
        @logger_one_job.info '**********************  Pass with: ' + get_unfilled_jobs.length.to_s + ' jobs to get *****************'
        # threads << Thread.new do
        one_job
        # end
        empty_attempts = 0
      else
        empty_attempts += 1
        sleep 3
      end
    end
    @logger_one_job.info '**********************  FINISH *****************'

    # main - wait end of all Threads
    threads.each(&:join)

  end

  def one_job
    needed_pages = get_unfilled_jobs.order(:id)

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
        @logger_one_job.info 'User agent: ' + usa

        response = HTTParty.get(job.link_job, {headers: {'User-Agent': usa}, })

        page = Nokogiri::HTML(response)

        title_job = page.at_css('h1.top-card-layout__title').text
        posted_job = page.at_css('span.posted-time-ago__text').text.strip
        description = page.at_css('section div.show-more-less-html__markup')
        posted_date = parse_duration_to_datetime(posted_job)
        @logger_one_job.info 'Title of Job: ' + title_job + ' | Job posted: ' + posted_date.to_s

        job.title = title_job
        job.description = description
        job.posted_at = posted_date
        job.attempts = job.attempts + 1

        if job.save
          @logger_one_job.info job.linkedin_id_job + ' | ' + job.type_job + ' | ' + job.location + ' : successfully saved'
        end

      rescue HTTParty::Error => e
        # Handle HTTP errors (e.g., 404)
        @logger_one_job.warn "HTTP Error: #{e.message} for #{job.linkedin_id_job}"
        job.attempts = job.attempts + 1
        job.save
      rescue StandardError => e
        # Handle other types of errors
        @logger_one_job.warn "Error: #{e.message} for #{job.linkedin_id_job}"
        job.attempts = job.attempts + 1
        job.save
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

    begin
      driver.get 'https://www.linkedin.com/'
      @custom_logger.info '--------- Start with ' + category.upcase + ' in ' + area.upcase + '---------'
    rescue HTTParty::Error => e
      @custom_logger.warn "HTTP Error: #{e.message} for #{job.linkedin_id_job}"
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message} for #{job.linkedin_id_job}"
    end

    begin
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
      sleep 4
      location.clear
      fill_form(location, area, true)
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message} for #{job.linkedin_id_job}"
    end

    begin
      # get first page ---------
      html_link_collection = list_one_page_jobs(driver, wait, 1)
      @list_link_jobs = check_and_save_links(html_link_collection, category, area)
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message} for #{job.linkedin_id_job}"
    end

    # get all next pages ---------
    page = 2
    while page <= deep_page
      begin
        button_page = wait.until do
          driver.find_element(xpath: "//button[contains(@aria-label, 'Page #{page}')]")
        end
        button_page.click
      rescue StandardError => e
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
    begin
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

      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection_2[link_collection_2.length / 3])
      sleep 7
      link_collection_3 = get_list_jobs(driver, wait)
      log_links(link_collection_3, '3', page)
      link_collection = link_collection | link_collection_3
      if link_collection.length > jobs_per_page - 1
        return link_collection
      end

      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", link_collection_3[(link_collection_3.length / 3) * 2])
      sleep 11
      link_collection_4 = get_list_jobs(driver, wait)
      log_links(link_collection_4, '4', page)
      link_collection = link_collection | link_collection_4
      if link_collection.length > jobs_per_page - 1
        return link_collection
      end

      # --------- go up if not all jobs yet ----------
      driver.execute_script("arguments[0].scrollIntoView({ behavior: 'smooth' });", scroll_down[0])
      sleep 13
      link_collection_5 = get_list_jobs(driver, wait)
      log_links(link_collection_5, '5', page)

      link_collection = link_collection | link_collection_3

    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message} for #{job.linkedin_id_job}"
    end

  end

  def check_and_save_links(object_links, category, area)
    list_link_jobs = []
    object_links.each_with_index do |obj, index|
      begin
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
          else
            @custom_logger.info 'Job: ' + job_id + ' already exist in DB'
          end
        end
      rescue StandardError => e
        @custom_logger.warn "Error: #{e.message}"
      end
    end
    @custom_logger.info 'Amount links: ' + object_links.length.to_s
    list_link_jobs
  end

  def log_links(object_links, n_pass, page)
    # object_links.each_with_index do |obj, index|
    #   link = obj.attribute("href")
    #   @custom_logger.info (index + 1).to_s + ': ' + link.to_s.truncate(83)
    # end
    @custom_logger.info '--------------  Page: ' + page.to_s + ' Pass: ' + n_pass + ' amount of links: ' + object_links.length.to_s
  end

  def get_list_jobs(driver, wait)
    begin
      html_link_collection = wait.until do
        driver.find_elements(xpath: '//a[contains(@class,"job-card-list__title")]')
      end
    rescue StandardError => e
      @custom_logger.warn "Error: #{e.message}"
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
    @logger_one_job = Logger.new("log/scraper_one_job.log")
    @logger_one_job.datetime_format = "%Y-%m-%d %H:%M:%S"
  end

  def get_unfilled_jobs
    Linkedin.where('title IS ? And posted_at IS ? And attempts < 5', nil, nil)
  end

  def get_unfilled_companies
    LinkedinCompany.where('name IS ? And attempts < 5', nil)
  end

  def get_unfilled_people
    LinkedinPerson.where('name IS ? And attempts < 5', nil).limit(21)
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

