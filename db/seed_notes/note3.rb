module Seeds
  class Note3
    def self.content
      <<-'NOTE'
        As the final release of Turbo 8 nears, there are a few “gotchas” worth knowing about that will make life easier as you start updating existing Rails Turbo apps to take advantage of all the new features that Turbo 8 offers, like page morphs

        1. Don’t scroll: preserve All The Things™
        There are two scroll properties in Turbo 8 that instruct the browser how to behave when users click on a link or submit a form: the new preserve property and the existing reset property.

        The reset property is the default behavior and it’s what Turbo has always been using. It starts pages at the top of the viewport when the user navigates after clicking a link. Nothing too surprising there—it’s how web browsers have worked for decades.

        The preserve property is the new kid on the block that works a bit differently. When the page loads the viewport stays put. That means if this property is mistakenly set on a content page and the user clicks on a link in the footer, they would continue seeing the footer as the content above gets updated.

        When upgrading to Turbo 8, keep scroll: reset as the default and make sure you manually test the pages where scroll: preserve is set to ensure it is behaving the way you intended.

        2. The autofocus attribute can unexpectedly cause the page to “jump” when a morph is applied
        I ran into an issue where a page would inexplicably jump to the top of the viewport when I set Turbo 8 to preserve: scroll. Turns out I had a form field with a <form autofocus> attribute for a search input in the user interface. When Turbo 8 diffed the DOM and refreshed, it would scroll to the autofocus form element no matter where I was on the page.

        Turbo 8 uses the ideomorph library to perform client-side DOM diffing operations. Callbacks exist that you could attach to with the browser debugger to troubleshoot these issues, but it’s not as straight forward as it ideally would be for a great debugging experience.

        3. Add a data-turbo-permanent attribute to form inputs and other HTML elements that you want to preserve between refreshes
        At some point you’ll have a Turbo 8 page morph wipe out a form when the data gets updated. This means users editing a form could lose their work. The solution? The data-turbo-permanent attribute can be added to form inputs or HTML elements that shouldn’t get updated by the server.

        Careful though; when the user saves this data to the server, it could overwrite the newer data on the server.

        4. Paying attention to caching is even more crucial for performance
        Since Turbo 8 morphing is conceptually a glorified page reloader, it’s important to pay attention to the performance of HTML page renditions. The good news is that there are ample solutions to this problem because developers have been solving it since HTTP arrived on scene with caching for decades.

        Yes, triggering the pull of an HTML document by the client will use more bandwidth than carefully calculated server-side diffs that are sent over the wire, but if the payloads are compressed via gzip or Brotli and the HTML document sizes aren’t insanely large, it is a small price to pay to not have to deal with the complexity of server-side diffing that the developers of Turbo 8 tried and abandoned.

        At first glance, Turbo 8 page morphing seems like a sledge hammer approach to building low latency UI, but when you consider how caching is built into browsers, proxies, and frameworks—it’s really an elegant and balanced way to solve the problem.

        5. Turbo Rails meta tags don’t appear where they’re called in the views
        The current Turbo helpers are implemented in a manner where meta tags are emitted into content_for :head, which is not where you may be calling the tags from view files. If you forget to include the content_for :head block your layouts, the Turbo meta tags won’t show up and you’ll wonder why your settings aren’t being picked up.

        For example, calling turbo_refreshes_with method: :morph, scroll: :preserve will append a meta tag in the content_for :head block. If your application calls it twice, you’ll have two of these tags appear in the :head block.

        When you first setup Turbo 8, take a few minutes to verify manually or with a test that the turbo meta tags do indeed appear in the </head> tags.

        If you need meta tags to appear where you call them, all the turbo helpers since Beta 2 have a _tag method that will emit the tag where it’s called in the view. For example, turbo_refreshes_with would be appended to content_for :head and turbo_refreshes_with_tag will appear where it’s called.

        The Rails Core team has decided to stick with this approach since changing it would break Rails apps being upgraded from Turbo 7 or older, but it is a level of indirection and inconsistency that’s helpful to understand and manually test.

        6. Slow down the development environment to see “loading” states
        When you start building applications in a development environment it’s a good idea to slow things down so you can get a better feel for how it looks and feels while running under adverse, slow, and congested conditions.

        I created the “Simulated Slowness” concern for my local development environment so I could experience all of the loading UI that my users might see if my server is under heavy load or the user is using the application from a universe far far away.


        # ./app/models/concerns/simulated_slowness.rb
        module SimulatedSlowness
          # Simulates a delay in a development environment so we don't get spoiled
          # by everything being super fast all the time.
          def simulate_delay(seconds = 5)
            if Rails.env.development?
              Rails.logger.debug "Sleeping for #{seconds} seconds 🥱"
              seconds.times.each do |n|
                sleep 1
                Rails.logger.debug "Sleeping for #{n} seconds 😴"
              end
              Rails.logger.debug "Awake after #{seconds} seconds 😀"
            end
          end
        end
        I include this in my code, in this example the ApplicationModel.


        class ApplicationModel < ActiveRecord::Base
          include SimulatedSlowness
        end
        Then from where you need to simulate production taking a while:


        def perform
          simulate_delay 4.seconds
        end
        In the development logs you’ll see this:


        web    | [ActiveJob] ... Sleeping for 5 seconds 🥱
        web    | [ActiveJob] ... Sleeping for 0 seconds 😴
        web    | [ActiveJob] ... Sleeping for 1 seconds 😴
        web    | [ActiveJob] ... Sleeping for 2 seconds 😴
        web    | [ActiveJob] ... Sleeping for 3 seconds 😴
        web    | [ActiveJob] ... Sleeping for 4 seconds 😴
        web    | [ActiveJob] ... Awake after 5 seconds 😀
        Now you’ll get a better feel for what your Turbo 8 UI should look like in between states when a worker queue, model, or something else, is running slower than usual.

        This will help you take loading states into account, which is particularly important for long running background jobs.

        7. The turbo-cable-stream-source tag can break grid and flex layouts
        When subscribing to Turbo Stream channels to receive page morph notifications, the turbo-cable-stream-source tag is emitted directly to where its called in the view. If this tag is emitted into a CSS grid, it might be included in the layout and create gaps that you’ll find surprising.

        You can either set the tag to display: none or emit the tag in a place that won’t break CSS grid or flex layouts, like this:


        <turbo-cable-stream-source channel="Turbo::StreamsChannel" signed-stream-name="IloybGtPaTh2YzJWeWRtVnlMMVZ6WlhJdk1RIg==--b4bcfff51ae4074540fdefbada55a237d68206bf960bd30a6684b310a255656c" class="hidden" style="display: none;" connected=""></turbo-cable-stream-source>
        <!-- Keep the cable tag out of the grid flow -->
        <div id="post_1" class="grid grid-columns-2">
          <!-- ... -->
        </div>
        8. Lazy loading content with turbo_frames still has its place
        It’s not really a “gotcha”, but turbo frames still have their place for lazy loading content. For example, if you have a long list of content that you don’t want to load all at once you’d paginate it with a lazily loading turbo_frame and a pagination library.

        They are also still useful for highly specialized and localized operations, like an autocomplete UI interaction when typing into a form input.

        Wrap up
        Turbo 8 is huge improvement over Turbo 7, but like any software there’s a few quirks about it that are helpful to keep in mind to make the upgrade and development process a bit smoother.

        As always, there’s a lot of room for improvement for the developer experience including better client-side debugging tools, a client-side API to handle conflict resolution for DOM merging elements like form inputs, documentation, and helper methods. All of these are great opportunities for community contributions to the Hotwire project suite.

        Overall, Turbo 8 continues the tradition of making Rails even more productive with its HTML-over-the-wire DOM diffing abilities and provide ample opportunities to remove code from most Rails applications.
      NOTE
    end
  end
end
