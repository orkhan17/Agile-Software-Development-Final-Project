defmodule WhiteBreadConfig do
  use WhiteBread.SuiteConfiguration

  suite name:          "Register",
        context:       UserManagementContext,
        feature_paths: ["features/user_registration.feature"]

  suite name:          "Login",
        context:       UserManagementContext,
        feature_paths: ["features/user_login.feature"]

   suite name:          "Search parking",
         context:       SearchParkingContext,
         feature_paths: ["features/zone_search_parking.feature"]

#   suite name:          "Add balance",
#         context:       AddBalanceContext,
#         feature_paths: ["features/user_adding_balance.feature"]

#   suite name:          "Add card",
#         context:       AddCardContext,
#         feature_paths: ["features/user_adding_card.feature"]

  suite name:          "Booking place",
        context:       BookigWithHourlyRealTimeContext,
        feature_paths: ["features/bookig_with_hourly_real_time_payment.feature"]
end
