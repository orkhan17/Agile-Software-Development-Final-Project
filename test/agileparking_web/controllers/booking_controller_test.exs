# defmodule AgileparkingWeb.BookingControllerTest do
#   use AgileparkingWeb.ConnCase

#   alias Agileparking.Bookings

#   @create_attrs %{end_date: "some end_date", payment_status: "some payment_status", start_date: "some start_date", zone_type: "some zone_type"}
#   @update_attrs %{end_date: "some updated end_date", payment_status: "some updated payment_status", start_date: "some updated start_date", zone_type: "some updated zone_type"}
#   @invalid_attrs %{end_date: nil, payment_status: nil, start_date: nil, zone_type: nil}

#   def fixture(:booking) do
#     {:ok, booking} = Bookings.create_booking(@create_attrs)
#     booking
#   end

#   describe "index" do
#     test "lists all bookings", %{conn: conn} do
#       conn = get(conn, Routes.booking_path(conn, :index))
#       assert html_response(conn, 200) =~ "Listing Bookings"
#     end
#   end

#   describe "new booking" do
#     test "renders form", %{conn: conn} do
#       conn = get(conn, Routes.booking_path(conn, :new))
#       assert html_response(conn, 200) =~ "New Booking"
#     end
#   end

#   describe "create booking" do
#     test "redirects to show when data is valid", %{conn: conn} do
#       conn = post(conn, Routes.booking_path(conn, :create), booking: @create_attrs)

#       assert %{id: id} = redirected_params(conn)
#       assert redirected_to(conn) == Routes.booking_path(conn, :show, id)

#       conn = get(conn, Routes.booking_path(conn, :show, id))
#       assert html_response(conn, 200) =~ "Show Booking"
#     end

#     test "renders errors when data is invalid", %{conn: conn} do
#       conn = post(conn, Routes.booking_path(conn, :create), booking: @invalid_attrs)
#       assert html_response(conn, 200) =~ "New Booking"
#     end
#   end

#   describe "edit booking" do
#     setup [:create_booking]

#     test "renders form for editing chosen booking", %{conn: conn, booking: booking} do
#       conn = get(conn, Routes.booking_path(conn, :edit, booking))
#       assert html_response(conn, 200) =~ "Edit Booking"
#     end
#   end

#   describe "update booking" do
#     setup [:create_booking]

#     test "redirects when data is valid", %{conn: conn, booking: booking} do
#       conn = put(conn, Routes.booking_path(conn, :update, booking), booking: @update_attrs)
#       assert redirected_to(conn) == Routes.booking_path(conn, :show, booking)

#       conn = get(conn, Routes.booking_path(conn, :show, booking))
#       assert html_response(conn, 200) =~ "some updated end_date"
#     end

#     test "renders errors when data is invalid", %{conn: conn, booking: booking} do
#       conn = put(conn, Routes.booking_path(conn, :update, booking), booking: @invalid_attrs)
#       assert html_response(conn, 200) =~ "Edit Booking"
#     end
#   end

#   describe "delete booking" do
#     setup [:create_booking]

#     test "deletes chosen booking", %{conn: conn, booking: booking} do
#       conn = delete(conn, Routes.booking_path(conn, :delete, booking))
#       assert redirected_to(conn) == Routes.booking_path(conn, :index)
#       assert_error_sent 404, fn ->
#         get(conn, Routes.booking_path(conn, :show, booking))
#       end
#     end
#   end

#   defp create_booking(_) do
#     booking = fixture(:booking)
#     %{booking: booking}
#   end
# end

defmodule AgileparkingWeb.BookingControllerTest do
  use AgileparkingWeb.ConnCase

  alias Agileparking.{Repo, Sales.Zone}
  alias Agileparking.Guardian
  alias Agileparking.Accounts.User
  alias Agileparking.Bookings.Booking
  import Ecto.Query, only: [from: 2]

  @create_attrs %{name: "sergi", email: "sergi@gmail.com", license_number: "1234567889", password: "12345678", balance: "12.43"}

  setup do
    user = Repo.insert!(%User{name: "sergi", email: "sergi@gmail.com", license_number: "1234567889", password: "12345678", balance: "12.43"})
    conn = build_conn()
           |> bypass_through(Agileparking.Router, [:browser, :browser_auth, :ensure_auth])
           |> get("/")
           |> Map.update!(:state, fn (_) -> :set end)
           |> Guardian.Plug.sign_in(user)
           |> send_resp(200, "Flush the session")
           |> recycle
    {:ok, conn: conn}
  end

  # Requirements 3.1
  test "Check database", %{conn: conn} do
    Repo.insert!(%Zone{id: 1, name: "Puiestee 112", hourlyPrice: 2, realTimePrice: 16, available: true})
    # ADD BOOKING
    conn = put conn, "/zones/1", %{id: 1, zone: [id: 1, end_date: "14:00", hourlyPrice: "2", pay_now: "true", payment_type: "Hourly", realTimePrice: "16", start_date: "12:00", total_payment: "2"]}
    conn = get conn, redirected_to(conn)
    # CHECKING DATABASE BY CHECKING BOOKING
    booking =  Repo.get!(Booking, 1)
    payment = booking.paymentType
    # CHECKING DATABASE BY CHECKING BOOKING IN BOOKINGS INDEX PAGE
    assert html_response(conn, 200) =~ ~r/Hourly/
  end

  # Requirements 3.2
  test "Invalid times/dates ", %{conn: conn} do
    Repo.insert!(%Zone{id: 1, name: "Puiestee 112", hourlyPrice: 2, realTimePrice: 16, available: true})
    # END IS BEFORE THE START TIME
    conn = put conn, "/zones/1", %{id: 1, zone: [end_date: "10:00", hourlyPrice: "2", pay_now: "true", payment_type: "Hourly", realTimePrice: "16", start_date: "12:00", total_payment: "2"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/The start always should occur before the end time/
  end

  # Requirements 3.3
  test "Blocks the corresponding parking space", %{conn: conn} do
    Repo.insert!(%Zone{id: 1, name: "Puiestee 112", hourlyPrice: 2, realTimePrice: 16, available: true})
    # FIRST BOOKING IS ADDED AND SLOT AVAILABILITY UPDATED
    conn = put conn, "/zones/1", %{id: 1, zone: [end_date: "13:00", hourlyPrice: "2", pay_now: "true", payment_type: "Hourly", realTimePrice: "16", start_date: "12:00", total_payment: "2"]}
    conn = get conn, redirected_to(conn)

    # SECOND BOOKING IS TRIED TO ADD BUT UNSUCCESSFUL BECAUSE THE SLOT IS NOT AVAILABLE
    conn = put conn, "/zones/1", %{id: 1, zone: [end_date: "13:00", hourlyPrice: "2", pay_now: "true", payment_type: "Hourly", realTimePrice: "16", start_date: "12:00", total_payment: "2"]}
    conn = get conn, redirected_to(conn)
    assert html_response(conn, 200) =~ ~r/There is no an available slot. Please choose new parking area/
  end
end
