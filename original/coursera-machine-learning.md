  [1]: https://www.coursera.org/learn/machine-learning/home/welcome

This holiday break, I somehow got into binge watching Coursera's [Stanford Machine Learning][1] course taught by Andrew Ng. I remember machine learning to be really math heavy, but I found this one more accessible.

Here are some notes for my own use. (I am removing all the fun examples, and making it dry, so if you're interested in machine learning, you should check out the course or its official notes.)

### Intro

Machine learning splits into supervised learning and unsupervised learning.

Supervised learning problems split to _regression_ problem (predict real valued output) and _classification_ problem (predict discrete valued output).

Unsupervised learning problems are the ones we don't have prior data of right or wrong. An example of unsupervised learning problem is clustering (find grouping among data). Another example is _Cocktail Party algorithm_ (identify indivisual voices given multiple recordings at a party).

### Linear regression with one variable

#### Model representation

<i>x<sup>(i)</sup></i> denotes _input variables_ (feature vector), and <i>y<sup>(i)</sup></i> denotes the output (target variable). A pair <i>(x<sup>(i)</sup>, y<sup>(i)</sup>)</i> is called a _training example_. A list of <i>1 .. m</i> training example is called a _training set_.

<img src='/images/ml1.jpg' style='width: 100%;'>

Supervised learning can be modeled as a process of coming up with a good function <i>h</i> called _hypothesis_ that predicts <i>y</i> from an unknown <i>x</i>.

For instance, given square footage, predict price of a house in some city. In the above, <i>h<sub>θ</sub>(x)</i> is modeled as a linear function. The hypothesis <i>h<sub>θ</sub>(x) = θ<sub>0</sub> + θ<sub>1</sub> x</i> is called _linear regression with one variable_ (or univariate linear regression).

These coefficients <i>θ<sub>0</sub></i> and <i>θ<sub>1</sub></i> are called _parameters_ (some textbooks call this **w** for weight vector).

#### Cost function

Basically figuring out the parameters <i>θ</i> vector is the name of the game.

<img src='/images/ml2.jpg' style='width: 100%;'>

We can turn this into an optimization problem that minimizes the _cost function J(θ)_, which in this case is a mean squared error.

Let's say a hypothesis is <i>h<sub>θ</sub>(x) = θ<sub>0</sub> x</i>. Depending on the value we put into <i>θ<sub>0</sub></i>, it could take different slopes as shown below. To get the intuition for the curve fitting, we can plot the cost function <i>J(θ)</i> against <i>θ</i>.

<img src='/images/ml3.jpg' style='width: 100%;'>

This makes it clear that there's a single minimum at <i>θ<sub>0</sub> = 1</i>.

For two parameter case it might look like a 3D bowl (or more complicated).

<img src='/images/ml4.jpg' style='width: 100%;'>

For some fixed set of <i>θ<sub>0</sub>, θ<sub>1</sub></i>, <i>h<sub>θ</sub>(x)</i> is a function of _x_, and the cost function captures the error between the training examples and the hypothesis.

For two-parameter case, we can try to visualize <i>J(θ<sub>0</sub>, θ<sub>1</sub>)</i> using a contour plot, smaller circles showing local maxima/minima.

#### Gradient descent

Given a hypothesis and its cost function, we can try to find the parameters that fits the data. One of the methods is gradient descent. In gradient descent, the parameters <i>θ<sub>0</sub>, θ<sub>1</sub></i> are incrementally changed to lower the cost. It turns out that we can determine the direction of walking by taking the partial derivative of _J(θ)_ by <i>θ<sub>j</sub></i> and multipiled by some learning rate _α_ (_η_ eta is used in textbooks).

<img src='/images/ml5.jpg' style='width: 100%;'>

Picking the right _α_ matters here, since if it's too large you might end up overshooting the target.

#### Gradient descent for linear regression

Linear regression with one variale is modeled using the hypothesis:<br>
<i>h<sub>θ</sub>(x) = θ<sub>0</sub> + θ<sub>1</sub> x</i>

The partial derivative of the cost function looks like this:

<img src='/images/ml6.jpg' style='width: 100%;'>

#### Linear algebra

Skipping the notes on linear algebra section.

- Learn how to multiply matrices and vectors.

### Multivariate linear regression

We can expand on the model _h<sub>θ</sub>(x)_ to incorporate multiple variables. For example, instead of just the size of a house, we can number of bedrooms, age etc.

<img src='/images/ml7.jpg' style='width: 100%;'>

Using vectors _θ_ and _x_, we can seamlessly build up on dimensions. The trick to express the whole thing as a vector multiplication is to hardcode _x<sub>0</sub>_ to 1.

#### Gradient descent for multivariate linear regression

Here's how we can find the parameters _θ_ using gradient descent.

<img src='/images/ml8.jpg' style='width: 100%;'>

Note that _x<sub>0</sub> = 1_.

#### Feature scaling

<img src='/images/ml9.jpg' style='width: 100%;'>

When using gradient descent, it's important get all the features in the similar scale so the algorithm won't overshoot. The convention is to get them in the neighborhood of -1 to 1 range, but -3 ~ 3 is considered ok.

#### Picking the learning rate

If the learning rate _α_ is too small, it's slow to converge. If it's too large, it may overshoot and not converge.

To debug this, it's recommended to plot cost function _J(θ)_ against the number of iterations, and see if it's dropping fast enough. The suggested increments for _α_ are 0.001, 0.003, 0.01, 0.03, ...

#### Polynomial regression

We can further expand the model _h<sub>θ</sub>(x)_ for polynomial function. The linear boundaries are straight lines and planes, whereas polynomial can express more complex curves and shaples like ellipsoid.

<img src='/images/ml10.jpg' style='width: 100%;'>

The amazing thing about is that as far as the learning algorithm is concerned, it doesn't really change anything. We just expand on the feature vector _x_ and add more terms like _x<sub>0</sub><sup>2</sup>_, _x<sub>0</sub><sup>3</sup>_,...

Note that the values are going to be wildly off once you start squaring, so we'd need feature scaling.

#### Normal equation

Thus far we've looked at minimizing _J_ using gradient descent. There's a second way to calculate this without iteration.

<img src='/images/ml11.jpg' style='width: 100%;'>

Apparently the slow part is calculating the inverse of a matrix, which is _O(n^3)_.

#### Vectorization

<img src='/images/ml12.jpg' style='width: 100%;'>

When implementing learning algorithms, avoid using for-loops and try to use vector and matrix multiplications. Generally the process of refactoring to use vector is called _vectorization_.

When using Octave, I found it useful to use the vectorized application of _h(x)_:<br>
<i>h<sub>θ</sub>(X) = Xθ</i>

Instead of calculating <i>h<sub>θ</sub>(x)</i> one row at a time, this calculates the whole matrix in a single shot.

### Logistic regression

#### Classification

Classification predicts discrete class. For instance, filtering email to spam/non-spam.

_y ∈ { 0, 1 }_

0 is called _negative class_, and 1 _positive class_ for binary classification problem. There are also multiclass classification problem with more y's.

One might try to apply linear regression to classfication problem by saying _y = 1_ when _h<sub>θ</sub>(x) >= 0.5_, but apparently it's not such a good idea.

<img src='/images/ml13.jpg' style='width: 100%;'>

For example, let's say the _x_ is size of a tumor and _y = 1_ means malignant, the above shows that adding a large data point can move the decison boundary to the right.

We can setup a better suited model for classification called _logistic regression_.

<img src='/images/ml14.jpg' style='width: 100%;'>

<img src='/images/ml15.png' style='width: 100%;'>

By plugging _θ<sup>T</sup>x_ into _logistic function g(z)_ that gives sigmoid curve, we can turn real values into 0, 1 signal. When _z == 0_, _g(z)_ returns 0.5. Another way of thinking about this is that _h<sub>θ</sub>(x)_ will now give us the probability that _y = 1_.

<img src='/images/ml16.jpg' style='width: 100%;'>

#### Decision boundary

Now that we can make _h<sub>θ</sub>(x)_ to output sigmoid (S-shaped) curve, we can treat _h<sub>θ</sub>(x) >= 0.5_ as _y = 1_. Looking at it from _z_ in _g(z)_, we can say that _y = 1_ when _z >= 0_, or _θ<sup>T</sup>x >= 0_.

So to understand the _decision boundary_, we can look at where _θ<sup>T</sup>x == 0_. Here are some examples of the decision boundaries.

<img src='/images/ml17.jpg' style='width: 100%;'>

Note that once _θ_ is picked, the decision boundary is a property of the hypothesis function (_h<sub>θ</sub>(x)_).

#### Cost function of logistic regression

The cost function for the logistic regression is a bit involved. We can't use the same cost function _J(θ)_ apparently because it will cause the output to be wavy (many local optima). Here's a convex alternative:

<img src='/images/ml18.jpg' style='width: 100%;'>

It looks gnarly at first, but remember that _y ∈ { 0, 1 }_. By multiplying _y_ or _(1 - y)_, half of the term goes away, emulating the "if _y = 1_" clauses. Another thing to keep in mind is that if _h<sub>θ</sub>(x)_ somehow manages to compute _h(x) = 0_ when _y = 1_, then this cost function will return a whopping penalty of _+∞_.

The gradient descent is actually surprisingly simple:

<img src='/images/ml19.jpg' style='width: 100%;'>

Whatever you plug into _h<sub>θ</sub>(x)_ is different, but the shape of the algorithm looks identical to that of linear regression version.

#### Optimization problem

The general problem of minimizing _J(θ)_ for _θ_ is called the optimization problem. Gradient descent is one approach is there are faster ones like conjugate gradient, BFGS, and L-BFGS. In Octave, `fminunc` is one of the optimizers.

#### Multiclass classification

To expand the model to deal with _y ∈ { 0, 1, ..., n }_, we take an approach calle one-vs-all where we divide the problem into _n + 1_ binary classification problems, and thus _n + 1_  hypotheses.

<img src='/images/ml20.jpg' style='width: 100%;'>

To make a prediction on a new _x_, pick the class that maximizes _h<sub>θ</sub>(x)_.
