require_relative 'spec_helper'

describe "Trip class" do

  describe "initialize" do
    before do
      start_time = Time.parse('2015-05-20T12:14:00+00:00')
      end_time = start_time + 25 * 60 # 25 minutes
      @trip_data = {
        id: 8,
        passenger: RideShare::User.new(
          id: 1,
          name: "Ada",
          phone: "412-432-7640"
        ),
        driver: RideShare::Driver.new(
          id: 10,
          name: "Drylan Batz",
          phone: "711-674-6798",
          vin: "1C9EVBRM0YBC564DZ",
          status: :AVAILABLE
        ),
        start_time: start_time,
        end_time: end_time,
        cost: 23.45,
        rating: 3
      }
      @trip = RideShare::Trip.new(@trip_data)
    end

    it "is an instance of Trip" do
      expect(@trip).must_be_kind_of RideShare::Trip
    end

    it "stores an instance of user" do
      expect(@trip.passenger).must_be_kind_of RideShare::User
    end

    it "stores an instance of driver" do
      # skip  # Unskip after wave 2
      expect(@trip.driver).must_be_kind_of RideShare::Driver
    end

    it "raises an error for an invalid rating" do
      [-3, 0, 6].each do |rating|
        @trip_data[:rating] = rating
        expect {
          RideShare::Trip.new(@trip_data)
        }.must_raise ArgumentError
      end
    end

    it "raises an error if start time is after end time" do

      test_end_time = Time.parse('2015-05-20T12:14:00+00:00')
      test_start_time = test_end_time + 25 * 60

      expect {
        @trip_data[:start_time] = test_start_time
        @trip_data[:end_time] = test_end_time
        RideShare::Trip.new(@trip_data)
      }.must_raise ArgumentError
    end

    it "calculate duration of the trip in seconds" do
      # Arrange
      test_start_time = Time.parse('2015-05-20T12:14:00+00:00')
      test_end_time = test_start_time + 25

      @trip_data[:start_time] = test_start_time
      @trip_data[:end_time] = test_end_time
      trip = RideShare::Trip.new(@trip_data)

      # Act
      duration = trip.duration

      # Assert
      expect(duration).must_equal 1500
    end
  end
end
