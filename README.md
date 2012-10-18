# Dropbox

This gem extends [Paperclip](https://github.com/thoughtbot/paperclip) with Dropbox storage.

## Installation

Put it in your `Gemfile`:

```ruby
gem "paperclip-dropbox"
```

Ano run `bundle install`.

## Usage

Example:

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar,
    :storage => :dropbox,
    :dropbox_credentials => "#{Rails.root}/config/dropbox.yml",
    :dropbox_options => {...}
end
```

Valid options for `#has_attached_file` are:

- `:dropbox_credentials` – A Hash, a File, or a path to the file where your
  Dropbox configuration is located

- `:dropbox_options` – A Hash that accepts some Dropbox-specific options (they
  are explained more below)

## Configuration

### The `:dropbox_credentials` option

It's best to put your Dropbox credentials into a `dropbox.yml`, and pass the path to
that file to `:dropbox_credentials`. One example of that YAML file:

```erb
app_key: <%= ENV["DROPBOX_APP_KEY"] %>
app_secret: <%= ENV["DROPBOX_APP_SECRET"] %>
access_token: <%= ENV["DROPBOX_ACCESS_TOKEN"] %>
access_token_secret: <%= ENV["DROPBOX_ACCESS_TOKEN_SECRET"] %>
user_id: <%= ENV["DROPBOX_USER_ID"] %>
```

This is a good practice; Don't put your credentials directly in your YAML file.
Instead set them in system environment variables, and then embed them here through ERB.

Note that all credentials mentioned here are required.

If you don't have your app key and secret yet, go to your [Dropbox apps](https://www.dropbox.com/developers/apps),
and create a new app there, which will then provide you your app key and secret.
Note that your app has to have the **Full Dropbox** access level (not the "App folder").
This is because the uploaded files have to be stored in your `Public/` directory.

If you're a relatively new Dropbox user, you'll probably have to enable your `Public` folder first by visiting
this link:

https://www.dropbox.com/enable_public_folder

After you obtain your app key and secret, you can obtain the rest of the credentials
through the `dropbox:authorize` rake task, which is described in more detail at the bottom of the readme.

You can also namespace your credentials in `development`, `testing` and `production` environments
(just like you do in your `database.yml`).

### The `:dropbox_options` option

You can pass it 3 options:

- `:path` – A block, provides similar results as Paperclip's `:path` option
- `:environment` – If you namespaced you credentials with environments, here you
  can set your environment if you're in a non-Rails application
- `:unique_filename` – Boolean

The `:path` option works in this way; you give it a block, and the return value
will be the path that the uploaded file will be saved to. The block yields attachment style,
and is executed in the scope of the class' instance. For example, let's say you have

```ruby
class User < ActiveRecord::Base
  has_attached_file :avatar,
    :storage => :dropbox,
    :dropbox_credentials => "...",
    :styles => { :medium => "300x300" },
    :dropbox_options => {
      :path => proc { |style| "#{style}/#{id}_#{avatar.original_filename}"}
    }
end
```

Let's say now that a new user is created with the ID of `23`, and a `photo.jpg` as his
avatar. The following files would be saved to the Dropbox:

```
Public/original/23_photo.jpg
Public/medium/23_photo_medium.jpg
```

The other file is called `photo_medium.jpg` because style names (other than `original`)
will always be appended to the filenames, for better management.

Files in Dropbox inside a certain folder have to have **unique filenames**, otherwise exception
`Paperclip::Storage::Dropbox::FileExists` is thrown. To help you with that, you
can set

```ruby
# ...
    :dropbox_options => {
      :unique_filename => true
    }
```

That will set `:path` to something that will be unique.

You can also pass in the `:download` option to attachment's `#url`:

```ruby
user.avatar.url(:download => true)
```

And that will return a download URL for that attachment (so, if a user clicks to
that link, the file will be downloaded, as opposed to being opened in the browser).

### The `dropbox:authorize` rake task

You just provide it your app key and secret:

```
$ rake dropbox:authorize APP_KEY=your_app_key APP_SECRET=your_app_secret
```

It will provide you an authorization URL which you have to visit, and after that
it will output the rest of your credentials, which you just copy-paste wherever
you need to.

If you're in a non-Rails application, to get this rake task, you must require it in
your `Rakefile`:

```ruby
# Rakefile
require "rake"
require "paperclip/dropbox/rake"
```

## License

[MIT](https://github.com/janko-m/paperclip-dropbox/blob/master/LICENSE)
