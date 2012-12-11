def error_message_credentials_not_found
  <<-EOS

### ERROR ###
Credential files spec/dropbox.yml and spec/app_folder.yml must exist.
Copy the example files in spec/ and fill in your app credentials.

  EOS
end

def error_message_wrong_access_types
  <<-EOS

### ERROR ###
:access_type must be "dropbox" in spec/dropbox.yml and "app_folder"
in spec/app_folder.yml. Each must contain credentials for an app that
has the corresponding access type.

  EOS
end
