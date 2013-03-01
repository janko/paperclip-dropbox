# Dropbox

This gem extends [Paperclip](https://github.com/thoughtbot/paperclip) with
[Dropbox](https://www.dropbox.com) storage.

## Installation

```sh
$ gem install paperclip-dropbox
```

## Dropbox Setup

You must [create a Dropbox app](https://www.dropbox.com/developers/apps) and
authorize it to access the Dropbox account you want to use for storage. You have
a choice of two access types: **App folder** or **Full Dropbox**. You can read
about the differences in [this wiki](https://github.com/janko-m/paperclip-dropbox/wiki/Access-types).

After creating your app, it will have an "App key" and "App secret". Provide
these and the access type (`dropbox` or `app_folder`) to the authorization Rake task:

```sh
$ rake dropbox:authorize APP_KEY=your_app_key APP_SECRET=your_app_secret ACCESS_TYPE=your_access_type
```

First it will give you an authorization URL that you must visit to grant the app access.
Then it will output your **access token**, and **user ID**.

For non-Rails projects, you must require this task in your `Rakefile`:

```ruby
# Rakefile
load "paperclip/dropbox/tasks.rake"
```

## Configuration

Example:

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar,
    :storage => :dropbox,
    :dropbox_credentials => "#{Rails.root}/config/dropbox.yml",
    :dropbox_options => {...}
end
```

### The `:dropbox_credentials` option

This can be a hash or path to a YAML file containing the keys listed in the
example below. These are obtained from your Dropbox app settings and the
authorization Rake task.

Example `config/dropbox.yml`:

```erb
app_key: <%= ENV["DROPBOX_APP_KEY"] %>
app_secret: <%= ENV["DROPBOX_APP_SECRET"] %>
access_token: <%= ENV["DROPBOX_ACCESS_TOKEN"] %>
access_token_secret: <%= ENV["DROPBOX_ACCESS_TOKEN_SECRET"] %>
user_id: <%= ENV["DROPBOX_USER_ID"] %>
access_type: <%= ENV["DROPBOX_ACCESS_TYPE"] %>
```

It is good practice to not include the credentials directly in the YAML file.
Instead you can set them in environment variables and embed them with ERB. Note
`access_type` must be either `"dropbox"` or `"app_folder"` depending on the
access type of your app; see **Dropbox Setup** above.

You can also nest your credentials in environments (like in your `database.yml`):

```erb
development:
  app_key: "..."
  ...
production:
  app_key: "..."
  ...
```

### The `:dropbox_options` option

This is a hash containing any of the following options:

- `:path` – Block, works similarly to Paperclip's `:path` option
- `:unique_filename` – Boolean, whether to generate unique names for files in
  the absence of a custom `:path`
- `:environment` – String, the environment name to use for selecting namespaced
  credentials in a non-Rails app

The `:path` option should be a block that returns a path that the uploaded file
should be saved to. The block yields the attachment style and is executed in the
scope of the model instance. For example:

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar,
    :storage => :dropbox,
    :dropbox_credentials => "#{Rails.root}/config/dropbox.yml",
    :styles => { :medium => "300x300" },
    :dropbox_options => {
      :path => proc { |style| "#{style}/#{id}_#{avatar.original_filename}" }
    }
end
```

Let's say now that a new user is created with the ID of `23`, and a `photo.jpg`
as his avatar. The following files would be saved to the Dropbox:

```
Public/original/23_photo.jpg
Public/medium/23_photo_medium.jpg
```

The other file is called `photo_medium.jpg` because style names (other than
`original`) will always be appended to the filenames, for better management.

Filenames within a Dropbox folder must be unique; uploading a file with a
duplicate name will throw error `Paperclip::Storage::Dropbox::FileExists`. If
you don't want to bother crafting your own unique filenames with the `:path`
option, you can instead set the `:unique_filename` option to true and it will
take care of that.

### URL options

When using `dropbox` access type, the `#url` method of attachments returns a
URL to a "landing page" that provides a preview of the file and a download link.
To make `#url` return a direct file download link, set the `:download` option as
a parameter:

```ruby
user.avatar.url(:download => true)
```

When using `app_folder` access type, `#url` always returns a direct link, and
setting the `:download` option simply forces the file to be downloaded even if
the browser would normally just display it.

## License

[MIT License](LICENSE)
