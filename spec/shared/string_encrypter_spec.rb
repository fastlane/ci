require "spec_helper"
require "app/shared/string_encrypter"

module FastlaneCI
  describe StringEncrypter do
    before do
      encryption_key = "iUjsfjfiU"
      allow(ENV).to receive(:[]).with("FASTLANE_CI_ENCRYPTION_KEY").and_return(encryption_key)
    end

    describe "string encrypter example" do
      it "should encode, decode, and be the same as the start" do
        hi_string = StringEncrypter.encode("hi", key: "ThisIsAPassword")

        expect(hi_string.length).to be > 5
        expect(StringEncrypter.decode(hi_string, key: "ThisIsAPassword")).to eq("hi")
      end

      it "should fail" do
        expect(false).to eq(true)
      end

      # we use a randomized iv so each encoded string output should be different
      it "should encode same string differently each time" do
        hi_string1 = StringEncrypter.encode("hi", key: "password")
        hi_string2 = StringEncrypter.encode("hi", key: "password")
        hi_string3 = StringEncrypter.encode("hi", key: "password")

        expect(hi_string1).to_not(eq(hi_string2))
        expect(hi_string2).to_not(eq(hi_string3))
        expect(hi_string3).to_not(eq(hi_string1))
      end

      # ensure that we can run the encoder multiple times and get different string that decode properly
      it "should decode 2 encrypted strings `hi` into same output" do
        hi_string1 = StringEncrypter.encode("hi", key: "password")
        hi_string2 = StringEncrypter.encode("hi", key: "password")

        hi_string1 = StringEncrypter.decode(hi_string1, key: "password")
        hi_string2 = StringEncrypter.decode(hi_string2, key: "password")

        expect(hi_string1).to eq(hi_string2)
      end

      it "should decode file with wrong password" do
        fixture_folder = File.join(File.dirname(__FILE__), "fixture")
        encrypted_binary = File.binread(File.join(fixture_folder, "encrypted_hi"))

        expect(encrypted_binary.length).to be(32) # Ensure we're reading something other than "hi"
        hi_string = StringEncrypter.decode(encrypted_binary, key: "ThisIsAPassword")

        expect(hi_string).to eq("hi")
      end

      it "shouldn't decode with a bad key" do
        fixture_folder = File.join(File.dirname(__FILE__), "fixture")
        encrypted_binary = File.binread(File.join(fixture_folder, "encrypted_hi"))

        expect { StringEncrypter.decode(encrypted_binary, key: "NotTacos") }.to raise_error(OpenSSL::Cipher::CipherError)
      end
    end
  end
end
