module FastlaneCI
  # Data source for Apple ID credentials
  class AppleIDDataSource
    def apple_ids
      not_implemented(__method__)
    end

    def delete_apple_id!(apple_id:)
      not_implemented(__method__)
    end

    def create_apple_id!(user:, password:, prefix: nil)
      not_implemented(__method__)
    end
  end
end
