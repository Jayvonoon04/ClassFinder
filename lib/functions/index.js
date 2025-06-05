// functions/index.js
const functions = require('firebase-functions');
const stripe = require('stripe')('sk_test_51RVXt72a6H3ZlQ94lVKwof6W0JTSeTS3fB2w3KMonr7KvkSDGm8KEtQxjcRjpnlbd7pVpl7XtFYYG7ZvXqw0J7YW00Xy2zpJv7'); //Stripe Secret Key

exports.createPaymentIntent = functions.https.onRequest(async (req, res) => {
  try {
    const { amount, currency } = req.body;

    const paymentIntent = await stripe.paymentIntents.create({
      amount,
      currency,
      payment_method_types: ['card'],
    });

    res.status(200).send({
      clientSecret: paymentIntent.client_secret,
    });
  } catch (error) {
    res.status(500).send({ error: error.message });
  }
});
