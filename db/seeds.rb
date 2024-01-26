require_relative 'seed_notes/index'

class Seeder
  def initialize
    @tags = {}
    %i[coding turbo strada mobile_development renewable_energy].each do |tag|
      @tags[tag] = Tag.create(name: tag)
    end
  end

  def seed
    puts 'Seeding...'
    notebook = Notebook.create(name: 'Turbo 8 & Strada Talk')
    create_notes(notebook)
    puts '...done seeding.'
  end

  private

  def create_notes(notebook)
    create_note1(notebook)
    create_note2(notebook)
    create_note3(notebook)
    create_note4(notebook)
    create_note5(notebook)
    create_note6(notebook)
  end

  def create_note1(notebook)
    Note.create(notebook:,
                note_type: 'blogpost',
                name: 'Turbo 8 in 8 minutes',
                tags: [@tags[:coding], @tags[:turbo]],
                resource_url: 'https://fly.io/ruby-dispatch/turbo-8-in-8-minutes/',
                content: Seeds::Note1.content)
  end

  def create_note2(notebook)
    Note.create(notebook:,
                note_type: 'blogpost',
                name: 'A happier happy path in Turbo with morphing',
                tags: [@tags[:coding], @tags[:turbo]],
                resource_url: 'https://dev.37signals.com/a-happier-happy-path-in-turbo-with-morphing/',
                content: Seeds::Note2.content)
  end

  def create_note3(notebook)
    Note.create(notebook:,
                note_type: 'blogpost',
                name: '8 Turbo 8 "Gotchas"',
                tags: [@tags[:coding], @tags[:turbo]],
                resource_url: 'https://fly.io/ruby-dispatch/8-turbo-8-gotchas/',
                content: Seeds::Note3.content)
  end

  def create_note4(notebook)
    Note.create(notebook:,
                note_type: 'blogpost',
                name: 'Turbo 8 Page Refreshes (+ Morphing) Explained at Length',
                tags: [@tags[:coding], @tags[:turbo]],
                resource_url: 'https://jonsully.net/blog/turbo-8-page-refreshes-morphing-explained-at-length/',
                content: Seeds::Note4.content)
  end

  def create_note5(notebook)
    Note.create(notebook:,
                note_type: 'youtube - transcritpt',
                name: 'Strada: Bridging the web and native worlds - Rails World 2023" by Jay Ohms',
                tags: [@tags[:coding], @tags[:strada], @tags[:mobile_development]],
                resource_url: 'https://www.youtube.com/watch?v=LKBMXqc43Q8',
                content: Seeds::Note5.content)
  end

  def create_note6(notebook)
    Note.create(notebook:,
                note_type: 'youtube - transcritpt',
                name: 'Just enough Turbo Native to be dangerous - Rails World 2023" by Joe Masilotti',
                tags: [@tags[:coding], @tags[:turbo], @tags[:mobile_development]],
                resource_url: 'https://www.youtube.com/watch?v=hAq05KSra2g',
                content: Seeds::Note6.content)
  end
end

Seeder.new.seed
