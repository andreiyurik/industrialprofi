{
  ru: {
    i18n: {
      plural: {
        keys: %i[one few many other],
        rule: lambda { |n|
          mod10 = n % 10
          mod100 = n % 100

          if mod10 == 1 && mod100 != 11
            :one
          elsif (2..4).include?(mod10) && !(12..14).include?(mod100)
            :few
          else
            :many
          end
        }
      }
    }
  }
}
