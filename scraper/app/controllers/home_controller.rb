class HomeController < ApplicationController

  def index
    # @countries = UpworkJob.group(:client_location).count
    @countries = UpworkJob.select("client_location,
                                    sum(client_hire_rate) as total_h_rate,
                                    sum(cast(client_paid_hours as integer)) as total_paid_hours,
                                    sum(cast(client_total_spent as integer)) as total_spent,
                                    count(id) as count_id")
                            .where("cast(client_hire_rate as integer) > 30")
                            .group(:client_location).order("count_id DESC")

    @type_project = UpworkJob.select("project_type, count(id) as count_id")
                            .where("cast(client_hire_rate as integer) > 30")
                            .group(:project_type).order("count_id DESC")

    @search_endpoint = UpworkJob.select("search_endpoint, count(id) as count_id")
                            .where("cast(client_hire_rate as integer) > 30")
                            .group(:search_endpoint).order("count_id DESC")

  end

end
