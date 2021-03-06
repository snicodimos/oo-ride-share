require 'csv'
require 'time'
require 'pry'

require_relative 'user'
require_relative 'trip'
require_relative 'driver'

module RideShare
  class TripDispatcher
    attr_reader :passengers, :trips, :drivers

    def initialize(user_file = 'support/users.csv', trip_file = 'support/trips.csv', driver_file = 'support/trips.csv')
      @passengers = load_users(user_file)
      @drivers = load_drivers(driver_file)
      @trips = load_trips(trip_file)
    end
    
    def load_users(filename)
      users = []

      CSV.read(filename, headers: true).each do |line|
        input_data = {}
        input_data[:id] = line[0].to_i
        input_data[:name] = line[1]
        input_data[:phone] = line[2]

        users << User.new(input_data)
      end

      return users
    end


    def load_trips(filename)
      trips = []
      trip_data = CSV.open(
        filename,
        'r',
        headers: true,
        header_converters: :symbol
      )

      trip_data.each do |raw_trip|
        driver = find_driver(raw_trip[:driver_id].to_i)
        passenger = find_passenger(raw_trip[:passenger_id].to_i)

        parsed_trip = {
          id: raw_trip[:id].to_i,
          driver: driver,
          passenger: passenger,
          start_time: Time.parse(raw_trip[:start_time]),
          end_time: Time.parse(raw_trip[:end_time]),
          cost: raw_trip[:cost].to_f,
          rating: raw_trip[:rating].to_i
        }
        # create an instance of trip
        trip = Trip.new(parsed_trip)
        # add created trip to the collection of passenger
        passenger.add_trip(trip)
        # add driven trip to the collection of drivers
        driver.add_driven_trip(trip)
        # add trip to the collection of trips
        trips << trip
      end

      return trips
    end

    def find_passenger(id)
      check_id(id)
      return @passengers.find { |passenger| passenger.id == id }
    end


    def load_drivers(filename)
      drivers = []

      CSV.read(filename, headers: true, header_converters: :symbol).each do |line|
        driver_data = {}
        driver_data[:id] = line[0].to_i
        driver_data[:vin] = line[1]
        driver_data[:status] = line[2].to_sym

        temp_passanger = find_passenger(line[0].to_i)
        driver_data[:name] = temp_passanger.name

        driver = Driver.new(driver_data)
        drivers << driver
      end

      return drivers
    end

    def find_driver(id)
      check_id(id)
      return @drivers.find { |driver| driver.id == id }
    end

    def inspect
      return "#<#{self.class.name}:0x#{self.object_id.to_s(16)} \
      #{trips.count} trips, \
      #{drivers.count} drivers, \
      #{passengers.count} passengers>"
    end

    def select_driver(user_id)
      available_drivers = []
      @drivers.each do |driver|
        if driver.status == :AVAILABLE && driver.id != user_id
          available_drivers << driver
        end
      end

      # By this point the drivers are avaiable (they don't have trip in progress)

      # Look for drivers that have never driven
      driver_with_no_trips = available_drivers.find do |driver|
        driver.trips.empty?
      end

      if driver_with_no_trips
        return driver_with_no_trips
      end

      available_drivers.sort_by! do |driver|
        driver.most_recent_trip
      end

      return available_drivers.first
      # Will give back nil if no available_drivers
    end

    def request_trip(user_id)

      # find user_id from the instance of a passanger
      passenger = find_passenger(user_id)

      available_driver = select_driver(user_id)


      # find { |driver| driver.status == :AVAILABLE && driver.id != passenger.id}

      # make an exception to let the user know there are no available drivers
      if available_driver == nil
        raise StandardError.new("There are no avaiable drivers")
      end

      # Trip detail end_time, cost adn rating set to nil
      trip = {
        id: @trips[-1].id + 1,
        driver: available_driver,
        passenger: passenger,
        start_time: Time.now,
        end_time: nil,
        cost: nil,
        rating: nil
      }
      # creating an instance of trip
      new_trip = Trip.new(trip)
      # Adding the new trio to the collection of trips for passanger
      passenger.add_trip(new_trip)
      # adding to the collection of trips for driver
      available_driver.add_driven_trip(new_trip)
      # adding to the collection of trips
      trips << new_trip

      return new_trip
    end

    private

    def check_id(id)
      raise ArgumentError, "ID cannot be blank or less than zero. (got #{id})" if id.nil? || id <= 0
    end
  end
end
