module Seeds
  class Note2
    def self.content
      <<~NOTE
                Last week, we presented in Rails World an upcoming addition to Turbo that uses morphing to offer smoother page updates and a simplified broadcasting system. This is the article version of the presentation I delivered.

        The starting point
        The traditional server-side full-page programming model that Rails nailed twenty years ago is incredibly productive. It lets you think of your application as a set of standalone screens, work on the initial rendering for those, and reuse that to handle all the interactions. All the alternatives I’ve seen, either within Rails or outside, feel like a downgrade in comparison. Old-fashioned and boring, this programming model delivers peak programming happiness.

        It’s no coincidence that Turbolinks in 2012 took pjax’s idea and introduced an important distinction: it would just replace the page body, not a customizable container. Combined with handling the browser history under the hood, you would get seamless faster navigation without sacrificing the happiest full-page rendering programming model. It took me years of Single Page Application torment to appreciate how revolutionary this idea was.

        Now, there are scenarios where you need higher UI fidelity, and Hotwire brought two answers for that: Turbo Frames and Turbo Streams. While fantastic abstractions, you need to pay a reduced-productivity tax to use them.

        See, your life gets more complex whenever you add partial updates to the mix. Now you have to care about screen regions, the elements they contain, and how interactions affect them. Good abstractions help, but you can’t shake the additional complexity off. You are just in a more complex realm.

        This is why we say that Turbo is progressive: go with the happy Turbo Drive path by default — and deviate from it when you need higher fidelity for specific screens or interactions.


        A progressive programming model
        A new challenge
        We recently announced that the company was working on a new product: a HEY Calendar.

        The development of the new product started in February of this year. We initially agreed on how we didn’t want to build a Javascript-heavy application to deal with the high-fidelity expectations of a calendar. Based on past experiences building calendar features in other products, this was a fair concern. We now had Turbo Streams and Frames, so we were optimistic we could do something different here.

        As we worked on the different screens, it became increasingly evident that raising fidelity would be a real hassle. On the one hand, partial updates were quite complex because rendering a calendar is difficult. On the other, we wanted to render many different elements on top of calendar events and to offer different views over those, which resulted in an explosion of partial updates. With the current Turbo menu, this felt like a burden.

        Morphing
        Looking into alternatives, I found morphdom, a DOM morphing library that Phoenix Live View used. The idea of DOM morphing is that, when you want to render a DOM tree, instead of replacing the existing one with it, you mutate it to achieve the desired state.

        I gave morphdom a quick try with the Calendar application. I was amazed by how much it improved sensations. I initially thought that it was improving rendering speed, but, in reality, the improvement came from keeping client-side state: scroll, focus, selected text, CSS transition states, etc.

        Eventually, we went with idiomorph because it solved the main problem with morphdom: adding ids everywhere to help the algorithm match nodes. This broke the seamless sensations we were aiming for.

        The solution
        After many internal discussions and several explorations, this is where we landed in a nutshell:

        Smoother updates
        We will introduce the concept of page refresh in Turbo. A page refresh happens when you render the current page again. For example, because you submit a form and get redirected back.

        Turbo will detect these page refreshes automatically. You can configure how to handle those declaratively via page directives, with config options to use morphing and preserve the scroll.

        <meta name="turbo-refresh-method" content="morph">
        <meta name="turbo-refresh-scroll" content="preserve">
        You can compare how the new system works in the following video, that shows how Basecamp’s Card Table improves with Turbo 8. Notice how scroll preservation makes a huge difference here.

        Of course, we could have achieved the same with stream actions, but that’s indeed the whole point here: not having to write those. In this case, the controller was just doing a regular redirection, and that remained unchanged:

        class Kanban::ColumnsController < ApplicationController
          #...

          def create
            @column = @bucket.record Kanban::Column.new(column_params), parent: @board
            redirect_to @board
          end
        end
        It’s important to highlight that we aren’t introducing new programming paths in Turbo. Instead, the goal is to get smoother page refreshes automatically when they make sense. Morphing is an implementation detail that Turbo will hide away in Turbo Drive, just like it does with history.pushState. In particular — and very intentionally — we are not introducing new alternatives to perform partial updates here.

        Simpler broadcasts
        Turbo currently supports broadcasting changes via stream actions expressing DOM updates. With the Calendar, this approach presented the same problems than partial updates: those DOM updates were complex, and we had an explosion of those.

        Page refreshes offered an excellent opportunity to simplify. We will introduce a new refresh stream action that reloads the page. Models can just broadcast this new action without having to worry about the DOM operations that reflect the change.

        This is better explained with an example. This represents part of the Card Table broadcasting system:


        The current broadcasting system
        As you can see, every domain change broadcasts a specific DOM operation to reflect the change in the page.

        With the new system, we can rely on a single page refresh action to achieve the same effect.


        The new broadcasting system
        This is the code we had to use in the Card Table to replace +100 lines of code:

        # Model
        class Board < ApplicationRecord
          broadcasts_refreshes
        end
        Regarding the views, you just subscribe to the stream normally:

        <%= turbo_stream_from @board %>
        You can see how it works in this video:

        The last two examples in the video are interesting because they correspond with changes that were not broadcasted before. The reason is that, with the traditional approach, each broadcast operation requires work, so you naturally focus on a set of key changes. With the new approach, the relationship gets inverted: what would need work is excluding specific changes from triggering a page refresh.

        As with page refreshes, we are aiming for a seamless system. This removes the coupling between models and views via DOM operations, and it doesn’t introduce a new concern of which sections get updated when specific models change.

        To make the system less intrusive, it will debounce broadcasted page refreshes automatically so that, if you generate multiple page refresh broadcasts in a row, only the last one makes it through. It doesn’t make sense to perform multiple page refreshes in such scenarios.

        Exclude regions from morphing
        Sometimes you want to prevent certain regions of the screen from being replaced when a page refresh happens. For example, if you have a popover menu open and a broadcasted page refresh happens. We will reuse the existing data-turbo-permanent that Turbo Drive offers to exclude DOM containers from morphing.

        <div data-turbo-permanent>
        </div>
        Here’s a video showing how the Card Table preserves a popup menu open when a broadcasted page refresh happens:

        Pull requests
        We plan to include this new system in Turbo 8. You can now check the ongoing Pull Requests for more details:

        turbo
        turbo-rails
        We’ll also make sure we update the official documentation to include the new features.

        Conclusion
        Our goal with the new system is to widen the happy programming path in Turbo based on full-page responses. We want to give you fewer reasons to abandon it, just like the original Turbolinks idea of replacing the body of the page did. The new system won’t deprecate Turbo streams because those still offer higher fidelity, but it should make them rarer.


        An enhanced happiest path
        DOM tree morphing is a fantastic innovation, but we don’t want to make it a new tool in your Turbo box, we want to make it an implementation detail. We aim to bring something seamless that works in most scenarios for most people most of the time.

        This will be part Turbo 8. I hope you are as excited as we are about it!
      NOTE
    end
  end
end
