#!/usr/bin/env python3
"""
Social Media Search Tool - X/Twitter & LinkedIn
Uses authenticated Chrome sessions via Playwright + CDP
"""

import sys
import json
import time
from playwright.sync_api import sync_playwright

def search_x(query, limit=10):
    """Search X/Twitter using authenticated session"""
    results = []

    with sync_playwright() as p:
        # Connect to existing Chrome instance via CDP
        browser = p.chromium.connect_over_cdp("http://localhost:9222")
        page = browser.contexts[0].pages[0] if browser.contexts[0].pages else browser.contexts[0].new_page()

        print(f"✅ Chrome already running", file=sys.stderr)

        # Navigate to X search
        search_query = query.replace(' ', '%20')
        search_url = f"https://x.com/search?q={search_query}&src=typed_query&f=live"
        page.goto(search_url, wait_until="domcontentloaded", timeout=60000)

        print(f"✅ Accessed X: ({page.context.pages.index(page) + 1}) {page.title()}", file=sys.stderr)

        # Wait for tweets to load
        time.sleep(5)

        # Extract tweet elements
        tweets = page.query_selector_all('[data-testid="tweet"]')

        print(f"✅ Found {min(len(tweets), limit)} tweets", file=sys.stderr)

        for i, tweet in enumerate(tweets[:limit]):
            try:
                # Extract text
                text_element = tweet.query_selector('[data-testid="tweetText"]')
                text = text_element.inner_text() if text_element else ""

                # Extract username from the tweet
                user_element = tweet.query_selector('[data-testid="User-Name"] a[href^="/"]')
                username = ""
                tweet_url = ""

                if user_element:
                    href = user_element.get_attribute("href")
                    if href:
                        username = href.strip("/")

                # Extract tweet URL from the time element
                time_element = tweet.query_selector('time')
                if time_element:
                    parent_link = tweet.query_selector('a[href*="/status/"]')
                    if parent_link:
                        href = parent_link.get_attribute("href")
                        if href:
                            tweet_url = f"https://x.com{href}"

                if text:
                    results.append({
                        "platform": "X",
                        "query": query,
                        "text": text,
                        "username": username,
                        "url": tweet_url,
                        "index": i + 1
                    })
            except Exception as e:
                print(f"⚠️  Error extracting tweet {i+1}: {e}", file=sys.stderr)
                continue

        browser.close()

    return results

def search_linkedin(query, limit=10):
    """Search LinkedIn using authenticated session with auto-scrolling"""
    results = []

    with sync_playwright() as p:
        # Connect to existing Chrome instance via CDP
        browser = p.chromium.connect_over_cdp("http://localhost:9222")
        page = browser.contexts[0].pages[0] if browser.contexts[0].pages else browser.contexts[0].new_page()

        print(f"✅ Chrome already running", file=sys.stderr)

        # Navigate to LinkedIn search
        search_query = query.replace(' ', '%20')
        search_url = f"https://www.linkedin.com/search/results/all/?keywords={search_query}"
        page.goto(search_url, wait_until="domcontentloaded", timeout=60000)

        print(f"✅ Accessed LinkedIn: ({page.context.pages.index(page) + 1}) {page.title()}", file=sys.stderr)

        # Wait for initial results
        time.sleep(3)

        # Scroll down 3 times and click "Show more results" button
        print("📜 Scrolling and clicking 'Show more results'...", file=sys.stderr)
        for scroll_attempt in range(3):
            # Scroll to bottom
            page.evaluate("window.scrollTo(0, document.body.scrollHeight)")
            time.sleep(2)

            # Try to click "Show more results" button
            try:
                button = page.query_selector('button:has-text("Show more results")')
                if button and button.is_visible():
                    print(f"   🖱️  Clicking 'Show more results' button...", file=sys.stderr)
                    button.click()
                    time.sleep(3)
            except:
                pass

        # Extract search results using LinkedIn's data attribute
        results_list = page.query_selector_all('[data-chameleon-result-urn]')

        print(f"✅ Found {min(len(results_list), limit)} LinkedIn results (after scrolling)", file=sys.stderr)

        for i, result in enumerate(results_list[:limit]):
            try:
                # Get text content from the result container
                text = result.inner_text()

                # Try to extract profile/post URL
                link_element = result.query_selector('a[href*="/in/"], a[href*="/posts/"], a[href*="/feed/update/"]')
                result_url = ""
                if link_element:
                    href = link_element.get_attribute("href")
                    if href:
                        # Clean up LinkedIn URLs (remove tracking params)
                        result_url = href.split("?")[0] if "?" in href else href
                        if not result_url.startswith("http"):
                            result_url = f"https://www.linkedin.com{result_url}"

                if text:
                    results.append({
                        "platform": "LinkedIn",
                        "query": query,
                        "text": text[:500],  # Limit to 500 chars
                        "url": result_url,
                        "index": i + 1
                    })
            except Exception as e:
                print(f"⚠️  Error extracting LinkedIn result {i+1}: {e}", file=sys.stderr)
                continue

        browser.close()

    return results

def main():
    if len(sys.argv) < 2:
        print("Usage: python3 locke-social-search.py \"search query\"", file=sys.stderr)
        sys.exit(1)

    query = sys.argv[1]

    print(f"🔍 Searching X for: {query}", file=sys.stderr)
    x_results = search_x(query)

    print(f"\n🔍 Searching LinkedIn for: {query}", file=sys.stderr)
    linkedin_results = search_linkedin(query)

    # Output JSON results
    output = {
        "query": query,
        "x_results": x_results,
        "linkedin_results": linkedin_results,
        "total": len(x_results) + len(linkedin_results)
    }

    print("\n" + "="*50, file=sys.stderr)
    print("📊 RESULTS", file=sys.stderr)
    print("="*50, file=sys.stderr)
    print(json.dumps(output, indent=2))

    # Save to file
    import time as time_module
    timestamp = int(time_module.time())
    output_file = f"/tmp/social-search-{timestamp}.json"
    with open(output_file, "w") as f:
        json.dump(output, f, indent=2)

    print(f"\n💾 Results saved to: {output_file}", file=sys.stderr)

if __name__ == "__main__":
    main()
