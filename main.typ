#import "@preview/ilm:1.4.0": *
#import "@preview/codly:1.2.0": *
#import "@preview/codly-languages:0.1.1": *
#import "@preview/pintorita:0.1.3"
#show raw.where(lang: "pintora"): it => pintorita.render(it.text)
#show: codly-init.with()
// #set text(font: "Cascadia Mono")

#codly(languages: codly-languages)

#set text(lang: "en")

#show: ilm.with(
  title: [The Juice Shop\ Practical Work Report],
  author: "Yuzhe Shi",
  date: datetime.today(),
  abstract: [
    This report presents some attacks on the Juice Shop web application, which is a vulnerable web application designed for security testing.
  ],
  preface: [
    #align(center + horizon)[
      Yuzhe Shi \
      #link("mailto:20108862@mail.wit.ie")
    ]
  ],
  bibliography: bibliography("refs.yml"),
  figure-index: (enabled: true),
  table-index: (enabled: true),
  listing-index: (enabled: true),
)

= Introduction<intro>

== All Completed Challenges

The following challenges have been completed:

+ Score Board
+ Privacy Policy
+ Bully Chatbot
+ Error Handling
+ Zero Stars
+ Login Admin
+ Admin Section
+ Empty User Registration
+ Five-Star Feedback
+ Forged Feedback
+ Login Jim
+ Login Bender
+ CAPTCHA Bypass
+ Deluxe Fraud
+ Payback Time
+ Multiple Likes

Among these challenges, the following five challenges are discussed in detail in this report:

+ Zero Stars
+ CAPTCHA Bypass
+ Deluxe Fraud
+ Payback Time
+ Multiple Likes

= Zero Stars
*Difficulty*: 1 star

*Challenge Description*: In this challenge you must bypass the normal client‑side controls on the customer feedback form. which normally prevent a zero‑star rating, and submit a “devastating” zero‑star review. 

*Category*: 
- Improper Input Validation (Because the server does not validate that the rating is within an acceptable range, allowing out‑of‑bound values.)

== Solution <zerostars>
#figure(caption: [Feedback form])[ 
  #image("ca.assets/image-20250306154158318.png", width: 60%)
]

A normal feedback is sent while the Network tab#footnote([In the Chrome DevTools.]). In the next step we will analyze the request sequence.

#figure(caption: [Feedback request])[ 
  #image("ca.assets/image-20250306154147261.png")
]

#figure(caption: [CAPTCHA request])[ 
  #image("ca.assets/image-20250312142847612.png")
]

The browser fetches the CAPTCHA from the server, which contains:

- `captchaId`
- `captcha`
- `answer` #footnote([`answer` is the calculated result of the CAPTCHA. This could be more difficult if this field is not provided. No idea why it is provided.])

After filling the form correctly, click the submit button.

We can see a `POST` request is sent to the server at endpoint `/api/Feedbacks`.

#figure(caption: [Copy feedback request cURL bash code])[ 
  #image("ca.assets/image-20250306154621471.png")
]

Copy the whole request as a cURL command. 

This contains the following important information:
- Endpoint URL
- JWT@jwt Authorization header
- Payload (`UserId`, `captchaId`, `captcha`, `comment`, `rating`)

#figure(caption: [Import cURL to Postman])[ 
  #image("ca.assets/image-20250306154559520.png")
]

Import the cURL command to Postman@postman, and set the `rating` to `0`. Then send the request.

It can be observed that the feedback is successfully submitted with a zero‑star rating.

== Analysis
*Walkthrough:*  
1. *Examination of the Feedback Form:*  
   The form restricts a zero‑star rating using client‑side mechanisms (e.g., the disabled attribute), which gives the illusion of secure input validation.  
2. *Intercepting the Request:*  
   Using browser developer tools, the student captures the outgoing POST request containing critical data such as the JWT, CAPTCHA details, and the rating value.  
3. *Modifying the Request:*  
   By copying the request into a tool like Postman and altering the rating value to `0`, the student effectively bypasses the client‑side check.  
4. *Submission and Verification:*  
   The modified request is accepted by the server, proving that there is no server‑side validation to enforce the expected rating range.

*Key Learnings:*  
- *Threat/Vulnerability Category:*  
  The challenge highlights *Improper Input Validation*, a vulnerability that occurs when client‑side checks are assumed to be sufficient without corresponding server‑side verification.  
- *Consequences of the Vulnerability:*  
  Relying solely on client‑side validation can lead to data integrity issues and enable attackers to submit unintended or malicious input, potentially compromising the application’s reliability.  
- *Violated Security Service:*  
  The primary security service violated here is *data integrity*. Without proper validation, the application fails to ensure that the data stored is within the expected parameters, which can have broader implications in real‑world scenarios.  
- *Prevention Measures:*  
  To mitigate such vulnerabilities, it is essential to implement robust server‑side validation. This ensures that all inputs, regardless of client‑side restrictions, are thoroughly checked against expected criteria before processing.


This exercise serves as a potent reminder that *trusting client-side validation is a critical misstep in secure application design*. The simplicity of bypassing these checks in the Zero Stars challenge underscores a fundamental security flaw that can be exploited not just for low‑impact issues like a manipulated review, but potentially for more serious breaches in different contexts. It's a best practice to *always validate user input on the server side*.


= CAPTCHA Bypass

*Difficulty*: 3 stars

*Description*: This challenge requires you to submit 10 or more customer feedbacks within a short time frame (10 seconds). The intent is to defeat the CAPTCHA that’s meant to block automated submissions. By automating the request (or using browser developer tools to replay the request rapidly), you can bypass the CAPTCHA mechanism.

*Category*: 
- Security Misconfiguration (The application over‑relies on client‑side CAPTCHA validation without robust server‑side rate limiting or anti‑automation measures.)
== Solution

This time is too short for manually submitting feedbacks. We need to automate the process using a script.

From @zerostars, we know the process of sending a feedback:

+ Request a CAPTCHA (`GET` `/rest/captcha`)
+ Send a feedback with the CAPTCHA answer (`POST` `/api/Feedbacks`)

The following Python script automates the process of sending feedbacks, with a existing JWT token copied from a previously logged in session. The other headers are not necessary, so they are omitted.

```python
  import requests
  URL = "http://localhost:3000/"

  CAPTCHA_URL = f'{URL}/rest/captcha'
  FEEDBACKS_URL = f'{URL}/api/Feedbacks'

  jwt = 'Bearer [DATA DELETED]'

  def get_captcha():
      response = requests.get(CAPTCHA_URL, headers={'Authorization': jwt})
      return response

  def send_feedback(feedback, userId = 1):
      captcha = get_captcha().json()
      
      response = requests.post(FEEDBACKS_URL, json={
        'captchaId': captcha['captchaId'],
        'captcha': captcha['answer'],
        'UserId': userId,
        'feedback': feedback,
        'rating': 114514
      }, headers={'Authorization': jwt})
      return response

  [send_feedback('Yuzhe&Nagisa') for _ in range(10)]
  ```

#figure(caption: [Successfully send requests using Python])[
  #image("ca.assets/image-20250306162932450.png")
]

The script sends 10 feedbacks successfully within 10 seconds.


== Analysis
*Walkthrough:*  
1. *CAPTCHA Retrieval:*  
   The automation script first sends a `GET` request to `/rest/captcha` to obtain the necessary CAPTCHA details, mirroring the behavior of a legitimate client.  
2. *Automated Submission:*  
   Utilizing the fetched CAPTCHA answer, the script then rapidly sends multiple `POST` requests to `/api/Feedbacks`, effectively bypassing the timing constraints set by the CAPTCHA.  
3. *Exploitation of Misconfiguration:*  
   The absence of proper server‑side rate limiting or behavior analysis allows the attacker to submit more feedbacks than intended within a short time frame, thereby revealing a misconfiguration in the system’s security controls.

*Key Learnings:*  
- *Threat/Vulnerability Category:*  
  This challenge highlights *Security Misconfiguration*, where over‑reliance on client‑side CAPTCHA validation and inadequate server‑side safeguards expose the application to automated abuse.  
- *Consequences of the Vulnerability:*  
  Without proper rate limiting, attackers can flood the system with fake or malicious submissions. This not only undermines data integrity but can also lead to potential resource exhaustion, affecting system availability.  
- *Violated Security Services:*  
  The primary security services compromised here are *integrity* (by polluting the feedback data) and *availability* (by potentially overwhelming the server with rapid, automated requests).  
- *Prevention Measures:*  
  Robust prevention requires implementing comprehensive server‑side validations, including strict rate limiting, behavioral analysis, and additional anti‑automation mechanisms to complement the CAPTCHA.

This challenge reinforces a crucial lesson in web application security: relying solely on client‑side controls such as CAPTCHA is insufficient. The ease with which the CAPTCHA was bypassed demonstrates that attackers can exploit even seemingly simple misconfigurations to subvert security measures. In my view, a layered security approach is essential; robust server‑side protections must always be in place to validate client actions and mitigate automated attacks. This exercise not only enhances our understanding of the specific vulnerability but also underscores the broader principle that effective security is built on multiple, interlocking defenses.



= Deluxe Fraud
*Difficulty*: 3 stars

*Description*: Here the goal is to obtain a deluxe membership without paying for it. This is achieved by intercepting the payment request (typically via a proxy tool) and modifying the parameters—such as sending an empty payment mode—so that the server grants you the membership without verifying the actual payment.

*Category*: 
- Improper Input Validation (Because the server fails to properly check that a legitimate, non‑empty payment type value was submitted.)

== Solution

Firstly, we need to know the process of purchasing a deluxe membership. The following is a request of purchasing a deluxe membership using `card` as the payment mode.

#figure(caption: [Purchasing membership request])[
  #image("ca.assets/image-20250310181921220.png")
  #image("ca.assets/image-20250310181929604.png")
]

We login to another user's account and navigate to the deluxe membership page. We can see that the user has not purchased the deluxe membership yet.

#figure(caption: [Send modified request])[
  #image("ca.assets/image-20250310182432485.png")
]

We can assume that `paymentId` is incremental. We can add $1$ to the `paymentId` and set the `paymentMode` to a random string ("1" is used here). Then send the request.

We can observe that the deluxe membership is successfully purchased without a proper payment.

== Analysis
*Walkthrough:*  
1. *Understanding the Payment Process:*  
   By analyzing a legitimate payment request, we observe the key parameters involved, including `paymentId` and `paymentMode`.  
2. *Manipulating the Request:*  
   Using a proxy tool, the attacker intercepts the request and alters the `paymentMode` field to a random or empty value.  
3. *Successful Exploitation:*  
   Upon sending the modified request, the server fails to validate whether an actual transaction was processed, granting the attacker deluxe membership without a valid payment.

*Key Learnings:*  
- *Threat/Vulnerability Category:*  
  This challenge falls under *Improper Input Validation*, where the application fails to enforce strict checks on submitted payment data.  
- *Consequences of the Vulnerability:*  
  - Loss of revenue, as unauthorized users can exploit this flaw to obtain paid services for free.  
  - Trust issues, since legitimate customers may feel discouraged if such exploits become widespread.  
  - Potential *legal repercussions* if fraudulent transactions are exploited at scale.  
- *Violated Security Service:*  
  The primary security service violated here is *authorization*—the system fails to verify whether the user is truly entitled to a deluxe membership. Additionally, *data integrity* is compromised, as the system stores invalid payment information.  
- *Prevention Measures:*  
  - *Strict Server-Side Validation:* The server should ensure that `paymentMode` contains only valid, expected values.  
  - *Transaction Verification:* Instead of relying on a simple parameter check, the system should validate payment through third-party processors before granting membership.  
  - *Tamper Detection:* Implementing digital signatures or request hashing could help detect and prevent parameter manipulation.

This challenge underscores the critical importance of *server-side validation* in financial transactions. The fact that altering a single request parameter can bypass payment verification suggests a fundamental design flaw. In my view, such a vulnerability is particularly dangerous because it directly impacts business revenue. A properly designed payment system should *never* trust client-side data alone—every transaction must be verified against an actual payment record. This exercise serves as a valuable lesson in *securing financial workflows* by enforcing strong integrity checks and external validation mechanisms.


= Payback Time
*Difficulty*: 3 stars

*Description*: In this challenge you exploit the shopping basket by placing an order with manipulated values (for example, a negative quantity) so that the total order value becomes negative. This “credits” money to your account, essentially making you rich.

*Category*: 
- Improper Input Validation (The application does not enforce that order quantities or prices must be positive numbers.)

== Solution

A very common idea of calculating the balance is:
$
  "balance" = "balance" + "price" * "quantity"
$

If we can set the `quantity` or `price` to a negative number, the balance will increase.

Modifying the `price` is not a good idea because we have to modify the product price in the DB which is unclear right now, so we can modify the `quantity` instead.

The following shows a normal order request:

#figure(caption: [Add item to basket])[
  #image("ca.assets/image-20250312151146646.png")
]

We can see a `POST` request is sent to `/rest/BastetItems` to add an item to the basket. The responce is not important. The request content is:

+ `ProductId`
+ `BasketId`
+ `quantity`

Same as the previous challenges, we can copy the request as a cURL command. 

#figure(caption: [Add a Item with negative quantity])[
  #image("ca.assets/image-20250306220151942.png")
]

After adding some negative quantitied items to the basket, we can see the total price is negative. Navigate back to the basket page, then checkout.

#figure(caption: [Shopping basket with negative price])[
  #image("ca.assets/image-20250306220242799.png")
]

== Analysis

*Walkthrough:*  
1. *Understanding the Order Process:*  
   The shopping cart updates the total price using:  
   $
   "balance" = "balance" + "price" * "quantity"
   $
   If `quantity` is negative, this results in an undeserved credit.  
2. *Intercepting and Modifying Requests:*  
   A normal `POST` request is sent to `/rest/BasketItems` to add an item, containing `ProductId`, `BasketId`, and `quantity`.  
3. *Exploiting the Vulnerability:*  
   By modifying the request and setting `quantity` to a negative number, the total order value turns negative.  
4. *Completing the Checkout:*  
   The system processes the checkout without validating the final amount, successfully applying the unintended credit.

*Key Learnings:*  
- *Threat/Vulnerability Category:*  
  - *Improper Input Validation*, as the backend does not enforce constraints on input values.  
  - *Broken Business Logic*, as the order system fails to prevent negative total amounts.  
- *Consequences of the Vulnerability:*  
  - Unauthorized financial gain, allowing users to generate illegitimate store credit.  
  - Business losses if exploited at scale, leading to fraudulent transactions.  
  - Possible legal consequences due to failure to secure financial transactions.  
- *Violated Security Services:*  
  - *Integrity:* The total order value is manipulated, violating trust in the transaction system.  
  - *Authorization:* Users can obtain financial benefits they are not entitled to.  
- *Prevention Measures:*  
  - *Strict Input Validation:* Ensure quantities and prices are non-negative before processing transactions.  
  - *Server-Side Checks:* Validate order totals before finalizing purchases.  
  - *Transaction Logging and Monitoring:* Detect and flag suspicious negative-value transactions for review.

*Analytical Perspective and Opinion:*  
This challenge highlights the importance of *server-side validation* in financial systems. While negative quantity logic may seem obvious to prevent, real-world cases show that such vulnerabilities often slip through due to assumptions about client-side validation. In my opinion, this exploit is particularly dangerous for businesses, as it directly affects revenue and can lead to *fraud at scale if automated*. Developers must take financial security seriously and implement *defensive programming techniques* to prevent such logical loopholes.


= Multiple Likes 
*Difficulty*: 6 stars #footnote([I think this challenge is overrated.])

*Description*: This challenge exposes a *race condition vulnerability* in the like feature of the application. By rapidly sending multiple concurrent like requests before the server updates the `likedBy` field, an attacker can bypass the intended one-like-per-user restriction. This results in a user being able to like the same review multiple times, which could be exploited for artificial engagement boosting.

*Category*: 

- Broken Access Control (The server fails to enforce proper restrictions, allowing a user to perform an action multiple times when it should be limited to once.)

- Security Misconfiguration (The backend does not handle concurrent requests correctly, leading to an inconsistent likedBy state and unintended behavior.)

== Solution

Observe the process of liking a review:

#figure(caption: [Put comment request])[
  #image("ca.assets/image-20250312152240105.png")
  #image("ca.assets/image-20250312152231317.png")
]

A `PUT` request is sent to `/rest/products/:productId/reviews` to like a review. The request content is:

+ `author`
+ `message`


The first idea is replay the request multiple times. However, this is not a good idea because the server will check the `likedBy` field and return an error if the user has already liked the review.

We can see if we send a duplicate request#footnote([Using same method as previous solutions, omitted.]), the server will return an error, as the following shows:

#figure(caption: [Try replay request but failed])[
  #image("ca.assets/image-20250310183316014.png")
  #image("ca.assets/image-20250310203259743.png")
]

The next idea is to send multiple requests simultaneously. If the server does not handle concurrent requests correctly (no lock when updating the `likedBy` field), we can bypass the restriction.

This phenomenon is called a *Race Condition*. 

#figure(caption: [Sequential Diagram of attack])[
  #image("ca.assets/like3timesseq.svg")
]

We can see that the server read the `likedBy` field 3 times before the rest of the requests are processed. So the server will read the same `likedBy` field (reading `[]`) 3 times#footnote([So called "Dirty read"]) and update it (assigning `[User 1]` to `likedBy` field) 3 times, while each time assigning the same list to the `likedBy` field. On the other hand, the `like` field is updated using atomic operations, so the `like` field will be updated correctly.#footnote([This is an assumpion. Not verified.])

`asyncio` and `aiohttp` are used to send multiple requests simultaneously. The following Python script sends 3 like requests simultaneously:

```python
import asyncio
import aiohttp
LIKE_URL = f'{URL}rest/products/reviews'

headers = {
    "Authorization": "Bearer [DATA DELETED]"
}

async def send_request(session, url, data):
    async with session.post(url, json=data, headers=headers) as response:
        return await response.text()

async def main():
    url = LIKE_URL
    payload = {"id": "8bajograRXKdiJuyB"}

    async with aiohttp.ClientSession() as session:
        tasks = [send_request(session, url, payload) for _ in range(3)]
        responses = await asyncio.gather(*tasks)
    
    for i, res in enumerate(responses):
        print(f"Response {i+1}: {res}")
        
import nest_asyncio
nest_asyncio.apply()  
await main()  
```

#figure(caption: [Successful results of 3 requests])[
  #image("ca.assets/image-20250310203331685.png")
]

== Analysis 

*Walkthrough:*  
1. *Understanding the Like Process:*  
   The application sends a `PUT` request to update the `likedBy` field, which stores the users who have liked a particular review.  
2. *Initial Replay Attempt:*  
   A simple replay of the request fails because the server correctly detects the duplicate like using the `likedBy` field.  
3. *Exploiting the Race Condition:*  
   By sending multiple concurrent like requests before the backend processes the first update, all requests read the same initial `likedBy` state (`[]`) and proceed to add the user separately, leading to multiple successful likes.  
4. *Successful Bypass:*  
   Due to improper concurrency handling, the `like` count is incremented multiple times while the `likedBy` field remains in an inconsistent state.

*Key Learnings:*  
- *Threat/Vulnerability Category:*  
  This falls under *Broken Access Control*, as users can bypass an intended restriction, and *Security Misconfiguration*, as the backend fails to properly handle concurrent updates.  
- *Consequences of the Vulnerability:*  
  - Artificial inflation of likes, potentially manipulating ranking algorithms or misleading users.  
  - Data inconsistency, where the `likedBy` field does not reflect the actual number of likes recorded.  
  - Broader implications for race conditions in other parts of the system, potentially leading to more severe exploits such as duplicate transactions.  
- *Violated Security Services:*  
  - *Integrity:* The like system does not accurately reflect user actions due to race conditions.  
  - *Authorization:* The system fails to enforce per-user like restrictions effectively.  
- *Prevention Measures:*  
  - *Atomic Database Operations:* Use transactions or atomic updates to ensure concurrent requests do not overwrite each other incorrectly.  
  - *Concurrency Locks:* Implement locks or optimistic concurrency control to prevent multiple requests from reading stale data.  
  - *Rate Limiting:* Enforce a short delay between consecutive like actions from the same user to mitigate rapid repeated submissions.

This challenge demonstrates how concurrency issues can lead to unintended security flaws. In my opinion, race conditions are particularly dangerous because they often go unnoticed in typical testing but can be devastating when exploited. The fact that a user can like a review multiple times is a symptom of a deeper issue—*improper state management in concurrent environments*. To prevent such vulnerabilities, developers must adopt secure coding practices that account for *asynchronous execution and concurrent data access*, particularly in web applications handling real-time user interactions.

= Conclusion

In conclusion, the Juice Shop challenges provide valuable insights into common web application vulnerabilities and security best practices. By exploring the Zero Stars, CAPTCHA Bypass, Deluxe Fraud, Payback Time, and Multiple Likes challenges, we have gained practical experience in identifying and exploiting security weaknesses such as improper input validation, security misconfigurations, and broken access controls. These exercises underscore the importance of robust server-side validation, secure payment processing, and concurrency control in safeguarding web applications against a wide range of threats. By applying these lessons to real-world scenarios, we can enhance our understanding of secure application design and contribute to a safer digital environment.


#pagebreak(weak: true)
#heading(outlined: false, numbering: none, [Statement of Original Authorship])

I, Yuzhe Shi, hereby declare that this report is my original work and has not been submitted for assessment in any other context. All sources of information have been duly acknowledged and referenced in accordance with the academic standards of the South East Technological University.

#v(1cm)

#table(columns: (auto, auto, auto, auto),
stroke: white,
inset: 0cm,

  strong([Signature(Seal):]) + h(0.5cm),
  repeat("."+hide("'")),
  h(0.5cm) + strong([Date:]) + h(0.5cm),
  datetime.today().display("[day] [month repr:long] [year]")
)
