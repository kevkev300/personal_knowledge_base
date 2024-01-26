module Seeds
  class Note1
    def self.content
      <<~NOTE
        Turbo 8 simplifies the development of live-updating Rails applications. It offers a dramatic leap forward from previous versions by minimizing the need for manually coding turbo frames and turbo stream responses. This advancement simplifies both the creation and maintenance of Rails applications making you even more productive.

        If you’re not familiar with Turbo, it’s a library used widely by Ruby on Rails applications to partially update pages, making them feel as responsive as single-page JavaScript applications. It’s similar to frameworks like HTMX, StimulusReflex, Phoenix LiveView, and Laravel LiveWire.

        Think of Turbo 8 as a really smart page reloader
        That’s an oversimplification, but the analogy is helpful to better understand how it works. The idea is this:

        Rails publishes when data changes - Rails models with broadcasts_refreshes will publish when a model has been created, updated, or destroyed via ActionCable.
        Pages subscribe to data changes they care about - When a page is loaded, the Turbo JavaScript scans it looking for <turbo-cable-stream-source/> tags. Each tag describes the model class and ID that is used to subscribe to data change notifications over ActionCable.
        When data changes on a page, the changes are applied to the page - When a model is updated, the subscribed pages receive notifications that something has changed. Turbo then requests the entire HTML page in the background via HTTP and compares the new HTML to the old HTML that’s currently loaded. If there are differences between the HTML files, it will apply only the differences to the page without reloading the entire page.
        That’s it. That’s the framework. It’s impressive how unimpressive it is. Most tutorials I’ve seen to date get caught up in comparing Turbo 7 with Turbo 8, but I think that makes it harder to understand, so forget everything you know about older versions of Turbo and let’s have a look at how things will work in the future by trying the beta.

        Install the Turbo 8 beta
        Install the Turbo 8 gem by adding this to your Gemfile or updating the existing turbo-rails entry.


        # Hotwire's SPA-like page accelerator [https://turbo.hotwired.dev]
        gem "turbo-rails", "~> 2.0.0.pre.beta"
        Restart your Rails server and get ready to go!

        Add the Turbo tag to the head of the page
        First thing you’ll need to do is add the tag in the <head/> tag of your application layout.


        <%= turbo_refreshes_with method: :morph, scroll: :preserve  %>
        <%= content_for :head %>
        This configures the behavior of Turbo 8 to “morph” the page and preserves the scroll position. The “old” behavior of Turbo would “replace” the entire page and “reset” the scroll position.

        You’ll still need the “traditional” behavior of Turbo to load content pages. If you apply method: :morph, scroll: preserve to everything, like content pages, you’ll get strange behaviors where the user clicks on the content and the page starts from the middle instead of the top.

        Pages subscribe to models to stay informed about changes and reload accordingly
        When you want a view to be updated, you’ll subscribe to it from your application view files. For example, if you have a blog post that you want to update when the author publishes a change, you’d add this to the top of ./app/views/post/show.html.erb


        <%= turbo_stream_from @post %>
        <h1><%= @post.title %></h1>
        This helper emits a tag like this in the HTML:


        <turbo-cable-stream-source channel="Turbo::StreamsChannel" signed-stream-name="IloybGtPaTh2YzJWeWRtVnlMMVZ6WlhJdk1RIg==--b4bcfff51ae4074540fdefbada55a237d68206bf960bd30a6684b310a255656c" connected=""></turbo-cable-stream-source>
        It might look cryptic, but within the signed-stream-name attribute is in the model class and ID Turbo subscribes to for changes. When the post is updated, Turbo gets a signal from the server, “this blog post changed”. It then makes an HTTP request for the current HTML page via JavaScript, diffs the new HTML to the DOM that’s already loaded, and merges the changes between the two so that it doesn’t have to reload the page.

        Great! Now we have a client that’s subscribing to our server for changes, but that’s only half of it. We need to tell Rails to publish changes to the Post model, so we add the following to the Post model.


        class Post < ApplicationRecord
          # When the model instance is changed, a message will sent over
          # ActionCable that notifies the page to reload.
          broadcasts_refreshes
        end
        Now when we create, update, or destroy a Post model, Rails will publish it over ActionCable and notify all the interested pages to reload if a change is made.

        How to Update Collections
        Collections all usually belong to something in an application. For example, a blog has many posts. We’d probably have a view somewhere that lists all of the posts for a blog at ./app/views/blog/posts/index.html.erb


        <%= turbo_stream_from @blog %>
        <%= render @blog.posts %>
        Then we add to our Post model the association that it belongs to a Blog. The important thing is that we add touch: true.


        class Post
          # Touch will update the timestamp on the blog when
          # a post is created, updated, or destroyed.
          belongs_to :blog, touch: true

          # When the model is changed, a message will sent over ActionCable.
          broadcasts_refreshes
        end
        Then the Blog model needs to broadcast its refreshes:


        class Blog
          has_many :posts
          broadcasts_refreshes
        end
        Now when a post is created, updated, or deleted, the blog model will get its timestamp updated and trigger a refresh on the pages listening for changes to the blog instance.

        What about collections that don’t belong to anything?
        In practice this is rare in an application. For example, a blog probably belongs to a user or an account, which could be “touched” similarly to above. Here’s what that might look like.


        class Blog < ApplicationRecord
          # Code from above removed for clarity
          belongs_to :user, touch: true
        end
        Then add broadcast_refreshes to the User model.


        class User < ApplicationRecord
          has_many :blogs
          # Blog will touch the account when something is changed.
          broadcasts_refreshes
        end
        And on the dashboard page that lists all of the users’ blogs, listen for changes to accounts:


        <%= turbo_stream_from current_user %>
        <%= render @current_user.blogs %>
        If your application has a collection that truly can’t be modeled with a parent object, you still have access to turbo streams to append to a list.

        Use Postgres or SQLite to broadcast changes
        Since Turbo 8 doesn’t have to push HTML payloads over WebSockets, the 8000 byte limit of the Postgres ActionCable adapter is no longer an issue. If you’re only using Redis or ActionCable pub-sub on a small to medium size application, this can simplify the infrastructure of your application by eliminating Redis as a dependency.

        If you’re deploying a SQLite application to production, you can install Litestack in your Rails application and use Litecable to publish change notifications over Turbo 8.

        Get excited again for the future of Rails development
        The tiny amount of effort required to make Rails applications auto-update is astonishing. Turbo 8 is still in beta, and there are lots of edge cases to consider for this approach to building Rails applications, but the technology is shaping up to be a promising way to further simplify Rails application development.

        If you’re heavily invested in Turbo Frames in versions prior to Turbo 8, the hardest part of moving over will probably be removing all the format.turbo_stream blocks in your controller code and turbo_frame tags from your views. If you believe git commits with thousands of deleted lines of code is productive, be prepared for some very productive days of development ahead.
      NOTE
    end
  end
end
