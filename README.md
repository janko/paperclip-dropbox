# Dropbox

This gem extends [Paperclip](https://github.com/thoughtbot/paperclip) with Dropbox storage.

## Installation

Put it in your `Gemfile`:

```ruby
gem "paperclip-dropbox"
```

And run `bundle install`.

## Usage

Example:

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar,
    :storage => :dropbox,
    :dropbox_settings => "#{Rails.root}/config/dropbox.yml"
end
```

Valid options for `#has_attached_file` are:

- `:dropbox_settings` – A `Hash`, a `File`, or a path to the file where your
  Dropbox configuration is located

- `:dropbox_options` – This can be used to overrride `:dropbox_settings` (for example,
  you have configuration in your YAML file, but you want to override some things
  that are specific for a certain attribute)

## Configuration

Example (`config/dropbox.yaml`):

```erb
app_key: <%= ENV["DROPBOX_APP_KEY"] %>
app_secret: <%= ENV["DROPBOX_APP_SECRET"] %>
access_token: <%= ENV["DROPBOX_ACCESS_TOKEN"] %>
access_token_secret: <%= ENV["DROPBOX_ACCESS_TOKEN_SECRET"] %>
```

You can also namespace them inside of `development`, `testing` and `production` environments
(just like you do with your `database.yml`).

There are 3 more **optional** configurations:

- `:access_type` – This is either `"app_folder"` or `"dropbox"` (defaults to `"app_folder"`)
- `:path` - Similar to Paperclip's `:path` option (defaults to `"<filename>"`)
- `:environment` - Here you can set your environment if you're in a non-Rails application

### The `:path` option

Let's say we've set `:path` to  `"<table_name>/<record_id>_<attachment_name>_<filename>"`. If a user with the ID of 13
uploads `photo.jpg` for his avatar, the file would be saved to

```
users/13_avatar_photo.jpg
```

The keywords are: `<filename>`, `<table_name>`, `<model_name>`,
`<attachment_name>` and `<style>`. Additionally, if you want to use a record's attribute, just
prefix it with `record_` (like the `<record_id>` above).

Filenames in Dropbox inside a folder have to be unique, otherwise exception
`Paperclip::Storage::Dropbox::FileExists` is thrown. To help you with that, you
can pass in `:unique_filename => true` to Dropbox configuration, which will
ensure uniqueness of filenames (this is the same as passing `:path => "<model_name>_<record_id>_<attachment_name>"`).

### Obtaining the access token

To obtain the access token, you can use the following rake task:

```
$ rake dropbox:authorize APP_KEY=your_app_key APP_SECRET=your_app_secret
```

And just follow the instructions.

## Credits

I found some solutions to my problems in **@dripster82**'s [paperclipdropbox](https://github.com/dripster82/paperclipdropbox) gem.

## License

[MIT](https://github.com/janko-m/paperclip-dropbox/blob/master/LICENSE)
