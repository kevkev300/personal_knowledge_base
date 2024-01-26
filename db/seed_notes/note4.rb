module Seeds
  class Note4
    def self.content
      <<~NOTE
                I’ve spent the last several days reading, consuming, and understanding the new Turbo 8 Page Refresh (+morphing) feature as much as possible. Like tracking down breadcrumbs between various blog posts, PR descriptions, PR conversations/comments, code comments, and implementation details, there’s a lot of little details sprinkled around Github and the Basecamp blog! Individually, none of these breadcrumbs painted the full picture for me. But I think I’ve got it all sorted out in my head now, so I wanted to write this extensive post explaining how it all works, how one might design their code with this system, some of its drawbacks, and why it’s so great. This is a long one. Strap in!

        Breadcrumbs...

        Getting Started
        As you’ve likely seen since you clicked on this article, Turbo 8 brings ‘Page Refresh’ events, powered by a new morphing system. I think more conversation is occurring around the latter piece (the technical means by which the HTML is updated, morphing), but the former (the new paradigm for when and how to use this new feature-set) is arguably more important to understand and less covered. I’d like to do that here.

        So what does it do? There’s a few ways to answer that question. First, ‘it’ being the new ‘Page Refresh’ event, allows you to skip a lot of boilerplate setup and get real-time, Turbo-Streamed updates on many of your pages with very, very little code to worry about. This is the paramount feature of the release, not morphing. Far less code to worry about and lots of that Rails-style magic making things just work. Morphing is a neat little bit of frosting on top, but refresh events very much are the cake.

        So, succinctly, Turbo 8’s Refresh Events grant us all the magic of real-time UI updates (that previously required lots of Turbo Stream code) with only a couple lines of Ruby. That’s the magic.

        When Page Refreshes Occur
        Alright, enough of the high-level. Let’s dig into this stuff. It’s neat, but understanding how it works and where to use it is both important and murky.

        Let’s start here: Turbo 8 isn’t suddenly React 🙂. Morphing isn’t used on every page change and these magic refresh-events aren’t an overhaul of Turbo Drive. Refresh events are used in two key moments of the user/webpage lifecycle. It feels like magic, but these two moments are very understandable.

        From the front-end perspective, we can essentially think of these ‘refresh events’ as triggers to refresh the page. Let’s keep it simple and ignore the morphing stuff for now — a refresh event is very simply just an event to trigger a page refresh; just like clicking the refresh button on the browser. As I mentioned, there are two moments that these refresh events get triggered. The first is when you submit a form and the back-end redirects you back to the same URL your browser is/was already viewing when you submitted the form. This is a fairly common pattern, especially if you have some kind of index page with a form to create a new object on that same page:

        image-20231225073106131

        Or any kind of timeline interface:

        image-20231225073652018

        In these scenarios the form POSTs the server and the server yields a redirect with a location that matches the current page path (/client/123, for the timeline example). Turbo will recognize that the paths match and instead of triggering a traditional Turbo Drive navigation, it will trigger a Page Refresh. Both re-request the full page from the server, but the latter now uses morphing to inject new content into the existing page rather than replacing the whole <body> as the former does.

        More on that later. For now, just remember that the first way Refresh Events are triggered is when your backend redirects you to the same path that you’re already viewing.

        The second moment that triggers a page refresh event is when someone else submits a form like the above examples. This is the real-time ‘magic’. When someone else changes some data on the server, the server can now automatically send a trigger to all other users looking at that page, essentially telling Turbo to execute a refresh event for them too. In practice, this looks like:

        image-20231225081205469

        So, in simplified theory, when someone changes something, everyone involved just hits refresh on their browser. That’s basically it! Since it happens automatically for us in real time, it’s magic!

        But this is also where we can realize some gains compared to the traditional Turbo Streams code that would be required to make these same kinds of real-time updates happen.

        Code Complexity
        Let me try to put this in perspective here. To accomplish this sort of setup with traditional Turbo Streams and broadcasting, we’d need several lines of code in our models to queue up the right background broadcasts and we’d need several different view files that are aware of every chunk of markup that might need to change:

        <%# ~/app/views/something/update.turbo_stream.erb %>

        <%# Update the counter %>
        <%= turbo_stream.replace "message_counter", partial: "message_counter", locals: { count: @messages.length } %>

        <%# Update the content of the thing that some other user might've changed %>
        <%= turbo_stream.update "container_div" do %>
          <div>
            <%= @thing.description %>
          </div>
        <% end %>

        <%# Remove some previous thing %>
        <%= turbo_stream.remove "another_component" %>
        And we’d need to coordinate and multiply all of the above by each page that we want to be real-time capable. It’s a lot!

        Let’s do… none of that.

        Instead, activating real-time Page Refreshes in a Rails app (assuming you already have traditional CRUD markup for the timeline I’ve mocked above) requires only need a single line of code added to the model:

        # ~/app/models/conversation.rb
        class Conversation < ApplicationRecord
          broadcasts_refreshes
          # ...
        end
        A single line of code added to the conversation index (the view mocked above):

        <%# ~/app/views/conversations/index.html.erb %>

        <%= turbo_stream_from @conversation %>

        <%# ... %>
        And a sort of global config to ‘turn on’ the page refreshes feature via meta tags in your layout:

        <%# ~/app/views/layouts/application.html.erb %>

        <%= turbo_refresh_method_tag :morph %>
        <%= turbo_refresh_scroll_tag :preserve %>
        That’s it. Those three changes alone fully enable all the ‘real-time magic’ that would’ve previously required a good amount of Turbo-Streams code before. Three lines of code for all users to suddenly have real-time UI updates.

        And I’m not leaving things out — we don’t need our controllers to support any turbo-stream formats, we don’t need any extra view files, etc. All the normal HTML stuff will just magically support real-time updates now.

        If you’ve delved into Turbo Streams and/or broadcasting in the last couple of years, you’ll know that this saves a huge amount of time and complexity. Instead of writing Turbo Stream partials and views (each of which likely render other partials and views…) and coordinating responses in all of our controllers, we can skip all of that. This implementation is incredibly simple and easy, comparatively. Just like clicking the refresh button in your browser, everything will be updated with the new content.

        But what is “Content”?
        If we have a high level understanding of how this new system works and what it does, the natural next question is, where’s the right place to integrate it? How does it fit into existing systems? How do we de-mystify some of the magic and actually do the thing?

        Let’s start with determining the right place to use this. You might’ve already deduced from the discussion on how it works that this new refresh event system isn’t usable everywhere. Additionally, as I mentioned above, this isn’t React — morphing itself isn’t available everywhere either. Turbo Drive navigations will still do full <body> swaps in most places. So where do we start?

        Well, let’s step back a bit. The Basecamp team, in their various demos, posts, and PRs, have talked about this system being for “content pages,” and implied that we ought to consider all of our pages carefully in determining whether or not they are content pages before activating refresh events on any given page. That’s a mouthful! What’s a ‘content page’? It’s not well defined, actually.

        My suggestion is this: a ‘content page’ is any page that a user encounters where they expect something new. That’s vague, but it’s true. It’s a reflection of a user’s expectations. We’ve all used the web for long enough to have reasonable expectations about what should happen every time we click something. Any time we expect a click to traverse somewhere new, that new place is a ‘content page’. That might be clicking into an article on a blog (the article is the ‘content page’), it might be an ‘about’ page on a website. It might be clicking the “Checkout” button while looking at your cart. That checkout interface is a content page.

        So, naturally, we wonder what isn’t a ‘content page’? To me, a non-content-page (or -interaction) is any interface whose use could be perceived as more of an application or intra-page interaction. Submitting a form on a page is a great example — if the response to that is simply “Thanks!”, that’s not a new content page. Paginating through a table of results may also be a non-content-page (though, depending on what the table is, how much info it reveals, and how canonically part of the page it is, it may be). If an interaction on a page yields a result that doesn’t change the canonical nature of the page, the result is itself not a new content page.

        Checkout is actually a great example. This is the RailsConf 2024 “Buy your Ticket” page:

        image-20231226120430835

        And when I clicked “Register”, I expected to go somewhere new: a place to buy a ticket. This is a content page. But when I scroll down, select one individual ticket, and hit “Continue”, I’m not expecting a whole new page:

        image-20231226120631628

        Instead, I’d expect some kind of in-page interaction to collect more details from me, or my payment information, or something like that. Canonically, I know that I’m already on the “buy a ticket” page. I’m just working through the process of buying a ticket. And wouldn’t you know it..

        image-20231226120800165

        Not exactly the styling I’d expect, but still an in-page interaction. This little checkout panel is not a content page of its own. This workflow is a great example of content pages vs. sub-pages. But identifying those splits in your own app isn’t always so clear.

        A decent rule of thumb may actually be scroll. If a user would reasonably expect their scroll to be reset in a navigation, it’s likely that they’ve just navigated to a content page. This is exactly what I experienced above. Since the “Tickets” panel was in a card design, I expected only that card to have its markup changed when I clicked “Continue”. I got a pop-over instead, but the premise was similar. Since I expected to not have my scroll reset, it would indicate that the next view (the pop-over) is not a content page.

        This is still a little hand-wavy. Let’s look at Basecamp (the company) for additional context and clarity. This new Turbo Page Refresh system was initially built for HEY’s upcoming Calendar system then demoed on Basecamp’s (the product) Card Table. Both of these are great examples of the content-page vs. not-content-page boundaries. While we haven’t seen the calendar interface yet, imagine any calendar interface: the current view, be it “today” or “this week” or “this month” is likely the content page. All of the events within that view are likely themselves small UI components with lots of interactivity (and/or edit-ability), but those elements are only ever visible or interactive when looking at the calendar view; those elements are not themselves content pages. They’re hosted on the content page:

        image-20231226070613784

        And as you make changes to those elements, you’d likely be redirected back to the content page (e.g. update an Event and get redirected back to the Calendar zoomed to that event’s week).

        The Basecamp (product) Card Table is similar. The table itself is the content page, and interacting with each card inside that table yields a redirection back to the table — back to the content page. Something like moving a card between columns illustrates this.

        image-20231225105018308

        Basecamp (the product) likely has a simple card controller that pushes the user back to the board when the card is moved:

        class Kanban::CardsController < ApplicationController
          #...

          def update
            @card.update! card_params
            redirect_to @board
          end
        end
        Both of these — the calendar/event interface and the card/board interfaces illustrate the “this is the content page, this is a sub-element primarily viewed on the content page” relationship well. And as such, they’re both exact candidates for where Page Refresh events can be employed with ease.

        And that’s the core of the high-level design: allow content pages to be automatically refreshed, for all users, when they, or their children, change.

        Stay on the Rails!
        It’s worth noting too that, even if the ‘content page’ paradigm is confusing, the actual implementation of this high-level design restricts it to only being used where a natural content page exists. Page Refreshes simply won’t fire in other cases.

        We previously covered the two moments that Page Refreshes can fire, but let’s look at the first (when you’re redirected back to the same path you’re already viewing) from a different perspective. If you’re following typical back-end workflows, the only time you’d be redirected back to a page you’re already viewing is if you have one of these ‘content page’ / parent-child relationships. If you didn’t and instead had a more default “a book is viewed and edited on /books/* and an author is viewed and edited on /authors/*” setup, the form POSTs / PATCHes would redirect to a different view. /books/242/edit would PATCH to /books/242 and (likely) redirect to (GET) /books/242. Since /books/242 != /books/242/edit, you’d get no Page Refresh event. The same holds for /authors/new to /authors/1. A form POST (or PATCH) redirecting back to the same path the user was already viewing tends to indicate that the parent-child relationship between the resources (where the child is canonically viewed and edited from the parent’s view) exists and is supported by the application.

        We see this with our calendar example. Let’s consider the week-wide view shown above as the yielded markup from GET /calendar/weeks/33. That markup contains the details and edit form for my event within it. If I were to make a change to the event, which I’d be doing from the calendar-level view, the form would PATCH to /events/142821 but ultimately the server ought to respond with a redirect back to /calendar/weeks/33 since the calendar-level view is the canonical place for me to view my events.

        This is the magic of Page Refreshes. They add sparkle to a workflow by simply understanding that “redirect back to what you’re already looking at” is an indicator of a workflow that can be enhanced. You can’t use the Page Refresh system outside of this workflow, but you also need not analyze every single potential-‘content-page’ in your application as to whether or not it should have Refreshes enabled — by their nature, Page Refreshes should only activate where appropriate.

        …you should still go through your application and determine where to activate and use this new stuff, I’m just making the point that it has your back 😉

        On Morphing
        Alright, so that’s Page Refreshes. In short, it’s a system that (a) detects when you’ve been redirected back to where you already are, and (b) broadcasts little “hey refresh yourself”‘s to other clients when data changes. Let’s talk about morphing.

        morphing

        Morphing is the frosting on the cake that makes Page Refreshes really feasible. If we had Page Refreshes without morphing, we’d have a lot of weirdness. For instance, considering other users that receive a “hey refresh yourself” directive, they might be in the middle of typing a long comment when the refresh hits. Without morphing, Turbo would replace the entire <body>. Bye-bye comment! 😭

        The other (and perhaps more consistently annoying) issue is scroll position. Without morphing, scroll position is always reset on <body> swap. We just discussed how this whole system is dedicated to nested (parent-child) resources.. how annoying would it be to edit a sub-resource on a page and have your scroll reset to the top of the page every time you edit that sub-resource. Imagine posting a comment at the bottom of this article and your page scroll resetting to the top of the page! This article is way too long to scroll it twice!

        Morphing solves both of these issues. I won’t go into it too much since others have (see Basecamp’s great post here), but morphing is a neat way of diffing two HTML trees and only applying the differences. Since it’s not a <body> swap and instead just individual element changes, scroll position can be retained as well. Neat stuff!

        A Couple Drawbacks
        Let’s finish off here with downsides. We know that Page Refreshes were built to save us time and complexity over manually building out all of our own Turbo Stream structures:

        Of course, we could have achieved the same with stream actions, but that’s indeed the whole point here: not having to write those.

        Jorge Manrubia, “A happier happy path in Turbo with morphing”

        But we also know that layers of abstraction bring costs, too. While I haven’t seen folks mention the costs / downsides of Page Refreshes yet, we ought to. There are two, primarily: slower real-time updates, and more web traffic. Both of these costs will be best understood when comparing a true Turbo Streams broadcasted system vs. a new Page Refresh broadcasted system.

        With traditional Turbo Streams, updates made by one user are propagated to other users thanks to Turbo Stream partials being rendered out in background jobs then pushed (actual HTML being sent) over websockets to other users watching that page. Two reasons why this is remarkably fast. The first is that, as mentioned, the HTML that needs to be painted into the page is contained within the websocket message. These Turbo Stream messages say “Hey append this to some container; here’s the markup div.p.span....etc”. So the front-end doesn’t have to send out a new request to the server to get the markup after the Turbo Stream message came in. The markup is in the message. Second, Turbo doesn’t have to do any HTML tree diffing with traditional Turbo Stream messages. These messages are more declarative and specific — Turbo simply finds the target element and appends, prepends, or etc, the HTML to it. It’s fast.

        In my experience, I often see traditional Turbo Stream broadcasts hit other users with updated markup before the user that made the change even gets their response fully rendered in their own browser. That is nuts! Traditional Turbo Streams are wicked fast.

        Since Page Refreshes instead ping users watching a page with “hey refresh yourself”, that browser must go request the markup for that page, wait for the full page’s markup to be rendered and delivered, then wait for the morphing algorithm to figure out the diffs and apply them.

        Now, is all of that really any substantial amount of time? No. For most folks and most apps we’re probably talking a difference of one hundred to a few hundred milliseconds. And since we’re talking about background real-time updates in the first place (it’s not someone waiting on a button they clicked), this simply doesn’t matter for most applications. Now, if you’re an instant-messaging / chat application where keeping the users ‘in sync’ as fast as possible, it might matter. But I think the realistic speed loss is well worth the complexity savings for almost all applications.

        That leaves us with the other cost: more web traffic. With traditional Turbo Streams, the broadcast markup is rendered in, then delivered from, a background system. Our web servers don’t take on additional request load when using traditional Turbo Streams. If anything, they can actually take on less since controllers can respond with significantly less content. Page Refreshes work differently. As client browsers receive “hey refresh yourself” pings, they’ll issue a full, traditional page requests for the updated page. That’s more traffic on our web servers. Is it something to be worried about? It really depends on your app, how much you intend to use Page Refreshes, your users, and your hosting setup. Is it going to be a huge difference? Probably not. But it’s worth calling out.

        Both of these drawbacks can be summed up to simply say that the Page Refresh paradigm is less efficient than going with a fully-manual Turbo Streams setup. But it’s significantly less complex. Your mileage may vary but this is a tradeoff I’m looking forward to accepting in most of the places I currently have Turbo Streams setup.

        Wrap Up
        This article is getting quite long so I’ll land the plane here, but hopefully you now understand now how to work with Page Refreshes, how to think about designing them into your application, and how they mesh with the object/domain design layer too. Expanding on a prior note above, I’d summarize it to say that:

        Page Refresh events are a system that (a) detects when you’ve been redirected back to where you already are and morphs in any differences to your existing DOM, and (b) broadcasts little “hey refresh yourself”‘s to other clients when data changes on the server, and morphs any differences into their existing DOMs.

        It’s a little less efficient than going with full-manual build-it-yourself Turbo Streams, but it saves you a lot of code complexity and developer time.

        Cheers!
      NOTE
    end
  end
end
