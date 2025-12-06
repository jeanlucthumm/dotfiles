# Notion: Retrieve ticket information

const NOTION_DB_ID = "23b6a82074ac81fa8307d7f0e5b1f6d2"

def ticket [
  id: string  # Ticket ID (e.g., "CORA2-165")
]: [nothing -> record] {
  with-env { NOTION_TOKEN: (get-key-notion), NOTION_DB_ID: $NOTION_DB_ID } {
    # Parse the ticket ID to extract the number
    let ticket_num = $id | split row "-" | last | into int

    # Build the filter for unique_id
    let filter = { property: "ID", unique_id: { equals: $ticket_num } }

    # Query the database
    let results = (
      notion-cli db query
        -a ($filter | to json)
        $env.NOTION_DB_ID
        --output json
      | from json
    )

    if ($results | is-empty) {
      error make -u { msg: $"Ticket ($id) not found" }
    }

    let page = $results | first

    # Get the page content as markdown
    let contents = notion-cli page retrieve $page.id --markdown

    {
      id: $id
      title: $page.title
      contents: $contents
    }
  }
}
