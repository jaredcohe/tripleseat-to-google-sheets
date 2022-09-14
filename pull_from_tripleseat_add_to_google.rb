# General libraries and other code
require 'oauth'
require 'json'
require 'csv'
require 'pp'
require_relative 'tripleseat_credentials.rb'

# Libraries for google
require "google/apis/sheets_v4"
require "googleauth"
require "googleauth/stores/file_token_store"
require "fileutils"

# Delete contents of log file
log_file = 'INSERT'
open(log_file, 'w') { |file| file.truncate(0) }

open(log_file, 'a') { |f|
  f.puts Time.now
}

def get_all_tripleseat_events_data(public_token, secret_key, log_file)
  consumer = OAuth::Consumer.new(public_token, secret_key, {:site => 'http://api.tripleseat.com'})
  access_token = OAuth::AccessToken.new(consumer)
  array_of_results = []

  # test response
  response = access_token.get('/oauth/test_request')
  if response.code != "200"
      # pp "ERROR - OAUTH PROBLEM"
      open(log_file, 'a') { |f|
          f.puts "ERROR - OAUTH PROBLEM"
      }
  else
      # Figure out how many pages of data
      open(log_file, 'a') { |f|
          f.puts "TESTTTTTTTT REQUEST WORKED"
      }

      page_number_of_events_data = 1
      events_page_json = get_page_of_tripleseat_events_data_as_json(access_token, page_number_of_events_data)

      open(log_file, 'a') { |f|
          f.puts "events_page_json worked"
      }
      number_of_events_pages = events_page_json["total_pages"]

      (1..number_of_events_pages).each do |page_number_of_events_data|
          open(log_file, 'a') { |f|
              f.puts "page_number_of_events_data #{page_number_of_events_data}"
          }

          events_page_json = get_page_of_tripleseat_events_data_as_json(access_token, page_number_of_events_data)

          # Loop through the results and add each row to the array to add to the google sheet
          events_page_json["results"].each do |row|
              row_to_add = []
              row_to_add << row["id"]
              name = !row["name"].nil? ? row["name"] : 0
              row_to_add << name
              status = !row["status"].nil? ? row["status"] : 0
              row_to_add << status

              lead_date = !row["lead"].nil? ? row["lead"]["created_at"] : row["created_at"]
              row_to_add << lead_date
              event_date = !row["event_date"].nil? ? row["event_date"] : 0
              row_to_add << event_date
              location = !row["location"].nil? ? row["location"]["name"] : 0
              row_to_add << location
              room = row["rooms"][0]["name"].strip
              row_to_add << room

              row_to_add << row["guest_count"]

              definite_date = ''
              if !row["status_changes"].nil?
                  row["status_changes"].each do |status_change|
                      if status_change["status"] == "DEFINITE"
                          definite_date = status_change["created_at"]
                      end
                  end
              end
              row_to_add << definite_date

              if (row["event_type"].nil?)
                  event_type = 0
              else
                  event_type = row["event_type"]
              end
              row_to_add << event_type

              # Owner
              owner_id = row["owned_by"]
              owner = ''

              case owner_id
              when 94601
                  owner = "Michelle Smith"
              when 94601
                  owner = "Sally Sidwell"
              when 34447
                  owner = "Michael Bluth"
              end

              row_to_add << owner

              # Add each custom field if present
              custom_fields_name_list = ["Success Manager", "Dedicated Staff", "Beverage Package", "Event Category"]

              custom_fields_name_list.each do |custom_fields_name|
                  custom_field_value = 0
                  row["custom_fields"].each do |custom_field|
                      if custom_field["custom_field_name"] == custom_fields_name

                          # Change nil to empty string so data doesn't repeat in following fields
                          custom_field_value = custom_field["value"].nil? ? "" : custom_field["value"]
                      end
                  end
                  row_to_add << custom_field_value
              end

              if (row["grand_total"].nil?)
                  grand_total = 0
              else
                  grand_total = row["grand_total"]
              end
              row_to_add << grand_total

              if (row["deposit_amount"].nil?)
                  deposit_amount = 0
              else
                  deposit_amount = row["deposit_amount"]
              end
              row_to_add << deposit_amount

              # The fees come under two categories in two arrays: "category_totals" and "billing_totals", this one is for the category_totals
              categories_name_list = ["Food", "Beverage", "Room Rental", "Shipping & Delivery", "Services & Fees", "Snacks"]
              categories_name_list.each do |categories_name|
                  categories_name_value = 0
                  if !row["documents"][0].nil?
                      row["documents"][0]["category_totals"].each do |category_total|
                          # pp category_total
                          if category_total["name"] == categories_name
                              categories_name_value = category_total["value"]
                          end
                      end
                  end
                  row_to_add << categories_name_value
              end

              # The fees come under two categories in two arrays: "category_totals" and "billing_totals", this one is for the billing_totals
              billing_totals_names = ["Gratuity", "Sales Tax", "Administrative Fee", "Service Fee"]
              billing_totals_names.each do |billing_totals_name|
                  billing_totals_total = 0
                  row["billing_totals"].each do |billing_total|
                      if billing_total["name"] == billing_totals_name
                          billing_totals_total = billing_total["total"]
                      end
                  end
                  row_to_add << billing_totals_total
              end

              if (row_to_add[2] != "LOST")
                  array_of_results << row_to_add
              end
          end
      end
    open(log_file, 'a') { |f|
        f.puts "XXXXXXXX"
    }

  end
  open(log_file, 'a') { |f|
      f.puts "FINISHED get_all_tripleseat_events_data 7777777777"
  }
  return array_of_results
end

def get_page_of_tripleseat_events_data_as_json(access_token, page_number)
    response = access_token.get("/v1/events.json?sort_direction=desc&order=created_at&show_financial=true&page=#{page_number}")
    events_page_json = JSON.parse(response.body)
    return events_page_json
end

open(log_file, 'a') { |f|
  f.puts "22222222"
}

public_token = SharedVariables.public_token
secret_key = SharedVariables.secret_key

open(log_file, 'a') { |f|
  f.puts "public_token #{public_token}"
  f.puts "secret_key #{secret_key}"
}

array_of_all_tripleseat_events_data = get_all_tripleseat_events_data(public_token, secret_key, log_file)
open(log_file, 'a') { |f|
  f.puts "array_of_all_tripleseat_events_data 8888888 #{array_of_all_tripleseat_events_data}"
}

rows_of_data = array_of_all_tripleseat_events_data.length

open(log_file, 'a') { |f|
  f.puts "rows_of_data #{rows_of_data}"
}

open(log_file, 'a') { |f|
    f.puts "STARTING GOOOOOOOGLE"
}

OOB_URI = "urn:ietf:wg:oauth:2.0:oob".freeze
APPLICATION_NAME = "Tripleseat Write to Sheet".freeze
CREDENTIALS_PATH = "INSERT".freeze
TOKEN_PATH = "INSERT".freeze
SCOPE = Google::Apis::SheetsV4::AUTH_SPREADSHEETS

open(log_file, 'a') { |f|
  f.puts "SCOPE #{SCOPE}"
}

# @return [Google::Auth::UserRefreshCredentials] OAuth2 credentials
def authorize
  client_id = Google::Auth::ClientId.from_file CREDENTIALS_PATH
  token_store = Google::Auth::Stores::FileTokenStore.new file: TOKEN_PATH
  authorizer = Google::Auth::UserAuthorizer.new client_id, SCOPE, token_store
  user_id = "default"
  credentials = authorizer.get_credentials user_id
  if credentials.nil?
    url = authorizer.get_authorization_url base_url: OOB_URI
    puts "Open the following URL in the browser and enter the " \
         "resulting code after authorization:\n" + url
    code = gets
    credentials = authorizer.get_and_store_credentials_from_code(
      user_id: user_id, code: code, base_url: OOB_URI
    )
  end
  credentials
end

# Initialize the API
service = Google::Apis::SheetsV4::SheetsService.new
service.client_options.application_name = APPLICATION_NAME
service.authorization = authorize

spreadsheet_id = "INSERT"

range = "Events Database!A7:AC#{rows_of_data+7}"

# Assign values to desired members of `request_body`. All existing members will be replaced:
request_body = Google::Apis::SheetsV4::ValueRange.new

request_body.values = array_of_all_tripleseat_events_data

response = service.update_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: "USER_ENTERED")

range = "Events Database!C1"
request_body.values = [[Time.new]]
response = service.update_spreadsheet_value(spreadsheet_id, range, request_body, value_input_option: "USER_ENTERED")

open(log_file, 'a') { |f|
    f.puts "FINISHED ENTIRE SCRIPT YAYYYYYYYY"
}
