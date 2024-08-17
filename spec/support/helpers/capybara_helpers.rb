module CapybaraHelpers
  def click_native_element(selector)
    page.driver.browser.execute_script("arguments[0].click();", find(selector).native)
  end
end