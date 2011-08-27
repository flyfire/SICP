;-- 3.1
(define (make-accumulator acc)
  (lambda (x)
    (set! acc (+ x acc))
    acc))

;-- 3.2
(define (make-monitored function)
  (define times-called 0)
  (define (mf message)
    (cond ((eq? message 'how-many-calls?) times-called)
	  ((eq? message 'reset-count) (set! times-called 0))
	  (else (set! times-called (+ times-called 1))
		(function message))))
  mf)

;-- 3.3
(define (make-account balance password)
  (define (withdraw amount)
    (if (>= balance amount)
      (begin (set! balance (- balance amount))
	     balance)
      "Insufficient funds"))
  (define (deposit amount)
    (set! balance (+ balance amount))
    balance)
  (define (dispatch m given-password)
    (if (eq? password given-password)
      (cond ((eq? m 'withdraw) withdraw)
	    ((eq? m 'deposit) deposit)
	    (else (error "Unknown request -- MAKE-ACCOUNT"
			 m)))
      (lambda (x) "Incorrect password")))
  dispatch)

;-- 3.4
(define (make-account balance password)
  (define wrong-tries 0)
  (define (withdraw amount)
    (if (>= balance amount)
      (begin (set! balance (- balance amount))
	     balance)
      "Insufficient funds"))
  (define (deposit amount)
    (set! balance (+ balance amount))
    balance)
  (define (dispatch m given-password)
    (if (eq? password given-password)
      (begin (set! wrong-tries 0)
	     (cond ((eq? m 'withdraw) withdraw)
		   ((eq? m 'deposit) deposit)
		   (else (error "Unknown request -- MAKE-ACCOUNT"
				m))))
      (begin (set! wrong-tries (+ wrong-tries 1))
	     (if (> wrong-tries 7)
	       call-the-cops
	       (lambda (x) "Incorrect password")))))
  dispatch)

; call-the-cops example:
(define call-the-cops
  (lambda (x) "HANDS UP!"))

; Test:
(define pw (make-account 100 'la))
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'la) 10)
; 90
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
; "Incorrect password"
((pw 'withdraw 'lag) 10)
"HANDS UP!"

;-- 3.5
; Given:
(define (monte-carlo trials experiment)
  (define (iter trials-remaining trials-passed)
    (cond ((= trials-remaining 0)
	   (/ trials-passed trials))
	  ((experiment)
	   (iter (- trials-remaining 1) (+ trials-passed 1)))
	  (else
	    (iter (- trials-remaining 1) trials-passed))))
  (iter trials 0))
(define (random-in-range low high)
  (let ((range (- high low)))
    (+ low (random range))))

; Solution:
(define (P x y)
  (< (+ (expt (- x 5) 2)
	(expt (- y 7) 2))
     (expt 3 2)))
(define (estimate-integral P x1 x2 y1 y2 trials)
  (define (experiment)
    (P (random-in-range x1 x2)
       (random-in-range y1 y2)))
  (monte-carlo trials experiment))

; Test:
(estimate-integral P 0 12 3 17 100)

; We can estimate pi with the fact that a circle area is (pi * r²)
; Hence pi ≅ (Monte Carlo results * rectangle area) / r²
(define pi-approx
  (/ (* (estimate-integral P 2.0 8.0 4.0 10.0 10000) 36)
     9.0))
pi-approx
; 3.1336

; This function has to be tested under MIT Scheme, neither gambit-scheme or
; SISC implements (random) - actually (random) is not part of R5RS nor SRFI.

; NB: using 2.0 instead of 2 in (estimate-integral) is primordial. If you pass
; two integers to (random-in-range low high), it will return another integer
; strictly inferior to your 'high' value — and this completely screws the
; Monte-Carlo method (it then estimates pi to ~3.00).

;-- 3.6
(define rand
  (let ((x random-init))
    (define (dispatch message)
      (cond ((eq? message 'generate)
	     (begin (set! x (rand-update x))
		    x))
	    ((eq? message 'reset)
	     (lambda (new-value) (set! x new-value)))))
    dispatch))

; Test:
(define random-init 0)
(define (rand-update x) (+ x 1)) ; Our not-very-evolved PNRG
(rand 'generate)
; 1
(rand 'generate)
; 2
((rand 'reset) 0)
; 0
(rand 'generate)
; 1

; It's interesting to notice that the lambda returned by a call to
; (rand 'reset) still has the closure we created as lexical scope:
x
; Error: undefined variable 'x'.

;-- 3.7
(define (make-account balance password)
  (define password-list (list password))
  (define (withdraw amount)
    (if (>= balance amount)
      (begin (set! balance (- balance amount))
	     balance)
      "Insufficient funds"))
  (define (deposit amount)
    (set! balance (+ balance amount))
    balance)
  (define (dispatch m given-password)
    (if (memq given-password password-list)
      (cond ((eq? m 'withdraw) withdraw)
	    ((eq? m 'deposit) deposit)
	    ((eq? m 'joint) (lambda (new-pass)
					  (set! password-list (cons new-pass password-list))
					  dispatch))
	    (else (error "Unknown request -- MAKE-ACCOUNT"
				  m)))
      (lambda (x) "Incorrect password")))
  dispatch)
(define (make-joint account password new-account-password)
  ((account 'joint password) new-account-password))

; Test:
(define peter-acc (make-account 100 'open-sesame))
((peter-acc 'withdraw 'open-sesame) 10)
; 90
(define paul-acc
  (make-joint peter-acc 'open-sesame 'rosebud))
((paul-acc 'withdraw 'rosebud) 15)
; 75
((peter-acc 'withdraw 'open-sesame) 10)
; 65

; This solution works, but is not perfect. For example, now we can access
; peter's account with paul's password:
((peter-acc 'withdraw 'rosebud) 10)
; 55
; One would expect that the password would be different for each account.

;-- 3.8
(define f
  (let ((init (- 1)))
    (lambda (x) (if (= init (- 1))
		  (set! init x)
		  0))))

;-- 3.9
;-- 3.10
;-- 3.11
;-- 3.12
(define (append! x y)
  (set-cdr! (last-pair x) y)
  x)
(define (last-pair x)
  (if (null? (cdr x))
      x
      (last-pair (cdr x))))
(define x (list 'a 'b))
;
; x-> [*|*]->[*|/]
;      |      |
;      v      v
;     [a]    [b]
;
(define y (list 'c 'd))
;
; y-> [*|*]->[*|/]
;      |      |
;      v      v
;     [c]    [d]
;
(define z (append x y))
;
; z-> [*|*]->[*|*]->[*|*]->[*|/]
;      |      |      |      |
;      v      v      v      v
;     [a]    [b]    [c]    [d]
;
(cdr x)
; (b)
(define w (append! x y))
; The trick is that now, w == x == (a b c d)
; Hence:
(cdr x)
; (b c d)

;-- 3.13
(define (make-cycle x)
  (set-cdr! (last-pair x) x)
  x)
(define z (make-cycle (list 'a 'b 'c)))
;         ___________
;       /             \
;      v               |
; z-> [*|*]->[*|*]->[*|*]
;      |      |      |
;      v      v      v
;     [a]    [b]    [c]
;
; Trying to compute (last-pair z) would result in an infinite loop - the stop
; condition cannot occur.

;-- 3.14
(define (mystery x)
  (define (loop x y)
    (if (null? x)
        y
        (let ((temp (cdr x)))
          (set-cdr! x y)
          (loop temp x))))
  (loop x '()))
; Mystery looks like a list-reversal function at first glance. Is it? Let's
; unroll it! We'll try with '(1 2 3)
;
; (mystery '(1 2 3))
;
; => (loop '(1 2 3) '())
; ===> temp is '(2 3)
; ===> x becomes '(1)
;
; => (loop '(2 3) '(1))
; ===> temp is '(3)
; ===> x becomes '(2 1)
;
; => (loop '(3) '(2 1))
; ===> temp is nil
; ===> x becomes '(3 2 1)
;
; => (loop '() '(3 2 1))
; ===> exits because x is nil ans returns y, i.e. '(3 2 1)
;
; It is a list-reversal function! Well done, self!

(define v (list 'a 'b 'c 'd))
;
; v-> [*|*]->[*|*]->[*|*]->[*|/]
;      |      |      |      |
;      v      v      v      v
;     [a]    [b]    [c]    [d]
;
(define w (mystery v))
; w-> [*|*]->[*|*]->[*|*]->[*|/]
;      |      |      |      |
;      v      v      v      v
;     [d]    [c]    [b]    [a]
;                           ^
;                          /
;          v -------------
v
; (a)
w
; (d c b a)

;-- 3.16
(define (count-pairs x)
  (if (not (pair? x))
      0
      (+ (count-pairs (car x))
         (count-pairs (cdr x))
         1)))
; Simpler case:
(define three-pairs (list 'a 'b 'c))
(count-pairs three-pairs)
; 3
; Double reference:
(define alist (list 'a))
(define twice-alist (cons alist alist))
(define four-pairs (list twice-alist))
(count-pairs four-pairs)
; 4
; Double reference at another level yields 5:
(define alist (list 'a))
(define alistlist (list alist))
(define five-pairs (cons alistlist alistlist))
(count-pairs five-pairs)
; 5
; And double double reference gives 7:
(define alist (list 'a))
(define twice-alist (cons alist alist))
(define seven-pairs (cons twice-alist twice-alist))
(count-pairs seven-pairs)
; 7

;-- 3.17
(define (count-pairs x)
  (define visited '())
  (define count 0)
  (define (visit pair)
    (if (not (memq pair visited))
      (begin (set! visited (cons pair visited))
             (set! count (+ 1 count)))))
  (define (populate-list x)
    (if (pair? x)
      (begin (populate-list (car x))
             (populate-list (cdr x))
             (visit x))))
  (begin (populate-list x)
         count))
; Tests (as defined in 3.16):
(count-pairs three-pairs)
; 3
(count-pairs four-pairs)
; 3
(count-pairs five-pairs)
; 3
(count-pairs seven-pairs)
; 3

;-- 3.18
(define (cycle? x)
  ; cycle? will walk the list and add each element to a stack until either the
  ; current element is not a pair (i.e. the list is not a cycle) or the current
  ; element is in the stack (i.e. there's a cycle).
  (define (test x stack)
    (if (pair? x)
      (if (memq x stack)
          #t
          (test (cdr x) (cons x stack)))
      #f))
  (test x '()))
; Test:
(define (last-pair x)
  (if (null? (cdr x))
      x
      (last-pair (cdr x))))
(define (make-cycle x)
  (set-cdr! (last-pair x) x)
  x)
(define z (make-cycle (list 'a 'b 'c)))
(cycle? z)
; #t
(cycle? (list 'a 'b 'c))
; #f

;-- 3.19
; "(This requires a very clever idea.)"
; I did not have this very clever idea, but Robert Floyd did: two pointers,
; walking the list at different speed (colloquially called the "tortoise and
; the hare" algorithm).
; More info: http://en.wikipedia.org/wiki/Cycle_detection
; A solution:
(define (cycle? x)
  (define (cycle-iter tortoise hare)
    (cond ((eq? tortoise hare)
            #t)
          ((or (not (pair? tortoise))
               (not (pair? hare))
               (not (pair? (cdr hare))))
            #f)
          (else (cycle-iter (cdr tortoise) (cddr hare)))))
  (if (pair? x)
    (cycle-iter x (cdr x))
    #f))

; Test:
(cycle? z)
; #t
(cycle? (list 'a 'b 'c))
; #f

;-- 3.20
; Environment diagrams

;-- 3.21
; Given queue functions:
(define (front-ptr queue) (car queue))
(define (rear-ptr queue) (cdr queue))
(define (set-front-ptr! queue item) (set-car! queue item))
(define (set-rear-ptr! queue item) (set-cdr! queue item))
(define (empty-queue? queue) (null? (front-ptr queue)))
(define (make-queue) (cons '() '()))
(define (front-queue queue)
  (if (empty-queue? queue)
      (error "FRONT called with an empty queue" queue)
      (car (front-ptr queue))))
(define (insert-queue! queue item)
  (let ((new-pair (cons item '())))
    (cond ((empty-queue? queue)
           (set-front-ptr! queue new-pair)
           (set-rear-ptr! queue new-pair)
           queue)
          (else
           (set-cdr! (rear-ptr queue) new-pair)
           (set-rear-ptr! queue new-pair)
           queue))))
(define (delete-queue! queue)
  (cond ((empty-queue? queue)
         (error "DELETE! called with an empty queue" queue))
        (else
         (set-front-ptr! queue (cdr (front-ptr queue)))
         queue)))

; Answer:
; The queue is actually empty. The rear-ptr isn't updated, but it doesn't
; matter - testing for the empty queue only bothers with front-ptr, and as soon
; as we add a new element to the queue, rear-ptr will be updated.
(define (print-queue q)
  (define (print-list l)
    (if (not (null? l))
      (begin (display (car l))
             (newline)
             (print-list (cdr l)))))
  (if (null? (car q))
    (display "The queue is empty.\n")
    (print-list (car q))))

; Test:
(define q (make-queue))
(print-queue q)
; The queue is empty.
(insert-queue! q 'a)
(print-queue q)
; a
(insert-queue! q 'b)
(print-queue q)
; a b
(delete-queue! q)
(print-queue q)
; b
(delete-queue! q)
(print-queue q)
; The queue is empty.

;-- 3.22
(define (make-queue)
  (let ((front-ptr '())
        (rear-ptr '()))
    (define (empty-queue?) (null? front-ptr))
    (define (front-queue)
      (if (empty-queue?)
          (error "FRONT called with an empty queue")
          (car front-ptr)))
    (define (insert-queue! item)
      (let ((new-pair (cons item '())))
        (cond ((empty-queue?)
               (set! front-ptr new-pair)
               (set! rear-ptr new-pair))
              (else
               (set-cdr! rear-ptr new-pair)
               (set! rear-ptr new-pair)))))
    (define (delete-queue!)
      (cond ((empty-queue?)
             (error "DELETE! called with an empty queue"))
            (else
             (set! front-ptr (cdr front-ptr)))))
    (define (print-queue)
      (define (print-iter l)
        (if (not (null? l))
          (begin (display (car l))
                 (newline)
                 (print-iter (cdr l)))))
      (if (empty-queue?)
        (display "The queue is empty.\n")
        (print-iter front-ptr)))
    (define (dispatch m)
      (cond ((eq? m 'front-ptr) front-ptr)
            ((eq? m 'rear-ptr) rear-ptr)
            ((eq? m 'front-queue) (front-queue))
            ((eq? m 'empty-queue?) (empty-queue?))
            ((eq? m 'insert-queue!) insert-queue!)
            ((eq? m 'delete-queue!) (delete-queue!))
            ((eq? m 'print-queue) (print-queue))
            (else (error "Unknown request -- MAKE-QUEUE" m))))
    dispatch))
; And some wrapper functions to behave exactly as before:
(define (front-ptr q)
  (q 'front-ptr))
(define (rear-ptr q)
  (q 'rear-ptr))
(define (front-queue q)
  (q 'front-queue))
(define (insert-queue! q item)
  ((q 'insert-queue!) item))
(define (delete-queue! q)
  (q 'delete-queue!))
(define (print-queue q)
  (q 'print-queue))

; Test (same as the previous question):
(define q (make-queue))
(print-queue q)
; The queue is empty.
(insert-queue! q 'a)
(print-queue q)
; a
(insert-queue! q 'b)
(print-queue q)
; a b
(delete-queue! q)
(print-queue q)
; b
(delete-queue! q)
(print-queue q)
; The queue is empty.

;-- 3.23
(define (make-deque) (cons '() '()))
(define front-ptr car)
(define rear-ptr cdr)
(define set-front-ptr! set-car!)
(define set-rear-ptr! set-cdr!)
(define (empty-deque? deque)
  (or (null? deque) (null? (front-ptr deque))))
(define (front-deque deque)
  (if (empty-deque? deque)
      (error "FRONT called with an empty deque" deque)
      (caar deque)))
(define (rear-deque deque)
  (if (empty-deque? deque)
      (error "REAR called with an empty deque" deque)
      (cadr deque)))
(define (front-insert-deque! deque item)
  (cond ((empty-deque? deque)
          (let ((new-pair (cons item (cons '() '()))))
            (set-front-ptr! deque new-pair)
            (set-rear-ptr! deque new-pair)
            deque))
        (else
          (let ((new-pair (cons item (cons '() (front-ptr deque)))))
            (set-car! (cdr (front-ptr deque)) new-pair)
            (set-front-ptr! deque new-pair)
            deque))))
(define (rear-insert-deque! deque item)
  (cond ((empty-deque? deque)
          (let ((new-pair (cons item (cons '() '()))))
            (set-front-ptr! deque new-pair)
            (set-rear-ptr! deque new-pair)
            deque))
        (else
          (let ((new-pair (cons item (cons (rear-ptr deque) '()))))
            (set-cdr! (cdr (rear-ptr deque)) new-pair)
            (set-rear-ptr! deque new-pair)
            deque))))
(define (front-delete-deque! deque)
  (cond ((empty-deque? deque)
          (error "DELETE! called with an empty deque" deque))
        (else
          (if (eq? (front-ptr deque) (rear-ptr deque))
            (begin (set-front-ptr! deque '())
                   (set-rear-ptr! deque '())
                   deque)
            (begin (set-front-ptr! deque (cddr (front-ptr deque)))
                   (set-car! (cdr (front-ptr deque)) '())
                   deque)))))
(define (rear-delete-deque! deque)
  (cond ((empty-deque? deque)
          (error "DELETE! called with an empty deque" deque))
        (else
          (if (eq? (front-ptr deque) (rear-ptr deque))
            (begin (set-front-ptr! deque '())
                   (set-rear-ptr! deque '())
                   deque)
            (begin (set-rear-ptr! deque (cadr (rear-ptr deque)))
                   (set-cdr! (cdr (rear-ptr deque)) '())
                   deque)))))
(define (print-deque d)
  (define (print-iter l)
    (if (not (null? l))
      (begin (display (car l))
             (newline)
             (print-iter (cddr l)))))
  (if (empty-deque? d)
    (display "The deque is empty.\n")
    (print-iter (car d))))

; Test:
(define d (make-deque))
(print-deque d)
; The deque is empty.
(front-insert-deque! d 'b)
(print-deque d)
; b
(front-insert-deque! d 'a)
(print-deque d)
; a b
(rear-insert-deque! d 'c)
(print-deque d)
; a b c
(front-delete-deque! d)
(print-deque d)
; b c
(rear-delete-deque! d)
(print-deque d)
; b
(rear-delete-deque! d)
(print-deque d)
; The deque is empty.
(rear-insert-deque! d 'z)
(print-deque d)
; z

;-- 3.24
(define (make-table same-key?)
  (let ((local-table (list '*table*)))
    ; We only need to redefine assoc to account for the same-key? test
    (define (assoc key records)
      (cond ((null? records) #f)
            ((same-key? key (caar records)) (car records))
            (else (assoc key (cdr records)))))
    ; -- snip -- ;
    dispatch))

;-- 3.25
; n-dimensional table
(define (lookup keys table)
  (if (not (pair? table))
    #f
    (if (null? keys)
      (cdr table)
      (lookup (cdr keys) (assoc (car keys) (cdr table))))))
; I now suspect that the whole SICP is a practical joke to find a way
; to make people write "car keys" in Scheme.
(define (insert! keys value table)
  (if (null? keys)
    #f
    (if (null? keys)
      (cdr table)
      (lookup (cdr keys) (assoc (car keys) (cdr table)))))
  (let ((subtable (assoc key-1 (cdr table))))
    (if subtable
        (let ((record (assoc key-2 (cdr subtable))))
          (if record
              (set-cdr! record value)
              (set-cdr! subtable
                        (cons (cons key-2 value)
                              (cdr subtable)))))
        (set-cdr! table
                  (cons (list key-1
                              (cons key-2 value))
                        (cdr table)))))
  'ok)



;-- 3.28
(define (logical-or a1 a2)
  (cond
    ((and (= a1 1) (= a2 1)) 1)
    ((and (= a1 1) (= a2 0)) 1)
    ((and (= a1 0) (= a2 1)) 1)
    ((and (= a1 0) (= a2 0)) 0)
    (else (error "Invalid signal"))))
(define (or-gate o1 o2 output)
  (define (or-action-procedure)
    (let ((new-value
		  (logical-or (get-signal o1) (get-signal o2))))
	 (after-delay or-gate-delay
			    (lambda ()
				 (set-signal! output new-value)))))
  (add-action! o1 or-action-procedure)
  (add-action! o2 or-action-procedure)
  'ok)

;-- 3.29
; De Morgan's law:
; a ∧ b ⇔ ¬(¬a ∨ ¬b)
(define (or-gate o1 o2 output)
  (let ((b1 (make-wire))
        (b2 (make-wire))
        (c1 (make-wire)))
    (inverter o1 b1)
    (inverter o2 b2)
    (and-gate b1 b2 c1)
    (inverter c1 output)
    'ok))

; The delay is inverter-delay + and-gate-delay + inverter-delay.
; (The first two inverters work in parallel).

;-- 3.30
(define (ripple-carry-adder As Bs Ss C)
  (if (list? As)
    (let ((c-out (make-wire)))
	 (full-adder (car As) (car Bs) C (car Ss) c-out)
	 (ripple-carry-adder (cdr As) (cdr Bs) (cdr Ss) c-out))
    (full-adder As Bs C Ss (make-wire))))

; Time complexity:
; Of one half-adder: (max (and-gate-delay+inverter-delay) (or-gate-delay))
; 				 + and-gate-delay
; Of one full-adder: (2 * half-adder-delay) + or-gate-delay
; Of a ripple-carry-adder of complexity n: n * full-adder-delay
;
; All in all... n * or-gate-delay
; 			 + 2n * and-gate-delay
; 			 + 2n * (max (and-gate-delay+inverter-delay) (or-gate-delay))

;-- 3.31
; accept-action-procedure! needs to run the (proc) it receives a first time
; so that the (proc) will know the original value of the wire and will be able
; to tell when that value changed (for example, to display).

;-- 3.32
; Given:
(define (make-wire)
  (let ((signal-value 0) (action-procedures '()))
    (define (set-my-signal! new-value)
	 (if (not (= signal-value new-value))
	   (begin (set! signal-value new-value)
			(call-each action-procedures))
	   'done))
    (define (accept-action-procedure! proc)
	 (set! action-procedures (cons proc action-procedures))
	 (proc))
    (define (dispatch m)
	 (cond ((eq? m 'get-signal) signal-value)
		  ((eq? m 'set-signal!) set-my-signal!)
		  ((eq? m 'add-action!) accept-action-procedure!)
		  (else (error "Unknown operation -- WIRE" m))))
    dispatch))
(define (call-each procedures)
  (if (null? procedures)
      'done
      (begin
        ((car procedures))
        (call-each (cdr procedures)))))
(define (get-signal wire)
  (wire 'get-signal))
(define (set-signal! wire new-value)
  ((wire 'set-signal!) new-value))
(define (add-action! wire action-procedure)
  ((wire 'add-action!) action-procedure))
(define (after-delay delay action)
  (add-to-agenda! (+ delay (current-time the-agenda))
                  action
                  the-agenda))
(define (propagate)
  (if (empty-agenda? the-agenda)
      'done
      (let ((first-item (first-agenda-item the-agenda)))
        (first-item)
        (remove-first-agenda-item! the-agenda)
        (propagate))))
(define (probe name wire)
  (add-action! wire
               (lambda ()        
                 (newline)
                 (display name)
                 (display " ")
                 (display (current-time the-agenda))
                 (display "  New-value = ")
                 (display (get-signal wire)))))
(define (make-time-segment time queue)
  (cons time queue))
(define (segment-time s) (car s))
(define (segment-queue s) (cdr s))
(define (make-agenda) (list 0))
(define (current-time agenda) (car agenda))
(define (set-current-time! agenda time)
  (set-car! agenda time))
(define (segments agenda) (cdr agenda))
(define (set-segments! agenda segments)
  (set-cdr! agenda segments))
(define (first-segment agenda) (car (segments agenda)))
(define (rest-segments agenda) (cdr (segments agenda)))
(define (empty-agenda? agenda)
  (null? (segments agenda)))
(define (add-to-agenda! time action agenda)
  (define (belongs-before? segments)
    (or (null? segments)
        (< time (segment-time (car segments)))))
  (define (make-new-time-segment time action)
    (let ((q (make-queue)))
      (insert-queue! q action)
      (make-time-segment time q)))
  (define (add-to-segments! segments)
    (if (= (segment-time (car segments)) time)
        (insert-queue! (segment-queue (car segments))
                       action)
        (let ((rest (cdr segments)))
          (if (belongs-before? rest)
              (set-cdr!
               segments
               (cons (make-new-time-segment time action)
                     (cdr segments)))
              (add-to-segments! rest)))))
  (let ((segments (segments agenda)))
    (if (belongs-before? segments)
        (set-segments!
         agenda
         (cons (make-new-time-segment time action)
               segments))
        (add-to-segments! segments))))
(define (remove-first-agenda-item! agenda)
  (let ((q (segment-queue (first-segment agenda))))
    (delete-queue! q)
    (if (empty-queue? q)
        (set-segments! agenda (rest-segments agenda)))))
(define (first-agenda-item agenda)
  (if (empty-agenda? agenda)
      (error "Agenda is empty -- FIRST-AGENDA-ITEM")
      (let ((first-seg (first-segment agenda)))
        (set-current-time! agenda (segment-time first-seg))
        (front-queue (segment-queue first-seg)))))
; And some functions from before:
(define (half-adder a b s c)
  (let ((d (make-wire)) (e (make-wire)))
    (or-gate a b d)
    (and-gate a b c)
    (inverter c e)
    (and-gate d e s)
    'ok))
(define (and-gate a1 a2 output)
  (define (and-action-procedure)
    (let ((new-value
           (logical-and (get-signal a1) (get-signal a2))))
      (after-delay and-gate-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! a1 and-action-procedure)
  (add-action! a2 and-action-procedure)
  'ok)
(define (inverter input output)
  (define (invert-input)
    (let ((new-value (logical-not (get-signal input))))
      (after-delay inverter-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! input invert-input)
  'ok)
(define (logical-not s)
  (cond ((= s 0) 1)
        ((= s 1) 0)
        (else (error "Invalid signal" s))))
; The or-gate from 3.28 and not the one from 3.29! This is important for the
; delays: the or-gate we made out of and-gates and inverters will have a higher
; delay than a 'vanilla' or-gate
(define (logical-or a1 a2)
  (cond
    ((and (= a1 1) (= a2 1)) 1)
    ((and (= a1 1) (= a2 0)) 1)
    ((and (= a1 0) (= a2 1)) 1)
    ((and (= a1 0) (= a2 0)) 0)
    (else (error "Invalid signal"))))
(define (or-gate o1 o2 output)
  (define (or-action-procedure)
    (let ((new-value
		  (logical-or (get-signal o1) (get-signal o2))))
	 (after-delay or-gate-delay
			    (lambda ()
				 (set-signal! output new-value)))))
  (add-action! o1 or-action-procedure)
  (add-action! o2 or-action-procedure)
  'ok)
; The queue from earlier:
(define (front-ptr queue) (car queue))
(define (rear-ptr queue) (cdr queue))
(define (set-front-ptr! queue item) (set-car! queue item))
(define (set-rear-ptr! queue item) (set-cdr! queue item))
(define (empty-queue? queue) (null? (front-ptr queue)))
(define (make-queue) (cons '() '()))
(define (front-queue queue)
  (if (empty-queue? queue)
      (error "FRONT called with an empty queue" queue)
      (car (front-ptr queue))))
(define (insert-queue! queue item)
  (let ((new-pair (cons item '())))
    (cond ((empty-queue? queue)
           (set-front-ptr! queue new-pair)
           (set-rear-ptr! queue new-pair)
           queue)
          (else
           (set-cdr! (rear-ptr queue) new-pair)
           (set-rear-ptr! queue new-pair)
           queue))))
(define (delete-queue! queue)
  (cond ((empty-queue? queue)
         (error "DELETE! called with an empty queue" queue))
        (else
         (set-front-ptr! queue (cdr (front-ptr queue)))
         queue)))
; And this one that we have to add ourselves because Abelson and Sussman were
; too lazy to write it down:
(define (logical-and a b)
  (cond ((and (= a 1) (= b 1)) 1)
        ((and (= a 1) (= b 0)) 0)
	   ((and (= a 0) (= b 1)) 0)
	   ((and (= a 0) (= b 0)) 0)
	   (else (error "Invalid signal"))))
; Delay values:
(define inverter-delay 2)
(define and-gate-delay 3)
(define or-gate-delay 5)
; Set up the agenda:
(define the-agenda (make-agenda))
; At this point, we can test our gates:
(define a1 (make-wire))
(define a2 (make-wire))
(define and_output (make-wire))
(probe 'and_output and_output)
(and-gate a1 a2 and_output)
(set-signal! a1 1)
(set-signal! a2 0)
(propagate)
; => Nothing is printed because output stays at 0
(set-signal! a2 1)
(propagate)
; Should print 'and_output 6  New-value = 1'
(set-signal! a2 0)
(propagate)
; Should print 'and_output 9  New-value = 0'

; The simulation given in SICP:
(define the-agenda (make-agenda)) ; Reset the agenda
(define input-1 (make-wire))
(define input-2 (make-wire))
(define sum (make-wire))
(define carry (make-wire))
(probe 'sum sum)
(probe 'carry carry)
(half-adder input-1 input-2 sum carry)
(set-signal! input-1 1)
(propagate)
; Should print 'sum 8  New-value = 1'
(set-signal! input-2 1)
(propagate)
; Should print 'carry 11  New-value = 1' and 'sum 16  New-value = 0'. Yay!

; Now let's answer the question:
; "The procedures to be run during each time segment of the agenda are kept in
; a queue. Thus, the procedures for each segment are called in the order in
; which they were added to the agenda (first in, first out). Explain why this
; order must be used. In particular, trace the behavior of an and-gate whose
; inputs change from 0,1 to 1,0 in the same segment and say how the behavior
; would differ if we stored a segment's procedure in an ordinary list, adding
; and removing procedures only at the front (last in, first out). "

; Let's try with the and gate. If its two inputs are at (0, 1), there are two
; ways to sequentially change them to (1, 0):
; FIFO: (0, 1) -> (0, 0) -> (1, 0)
; LIFO: (0, 1) -> (1, 1) -> (1, 0)
; The second way will have the output flicker from 0 to 1, whcih we don't want.

;-- 3.33
; Given:
(define (adder a1 a2 sum)
  (define (process-new-value)
    (cond ((and (has-value? a1) (has-value? a2))
           (set-value! sum
                       (+ (get-value a1) (get-value a2))
                       me))
          ((and (has-value? a1) (has-value? sum))
           (set-value! a2
                       (- (get-value sum) (get-value a1))
                       me))
          ((and (has-value? a2) (has-value? sum))
           (set-value! a1
                       (- (get-value sum) (get-value a2))
                       me))))
  (define (process-forget-value)
    (forget-value! sum me)
    (forget-value! a1 me)
    (forget-value! a2 me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value)  
           (process-new-value))
          ((eq? request 'I-lost-my-value) 
           (process-forget-value))
          (else 
           (error "Unknown request -- ADDER" request))))
  (connect a1 me)
  (connect a2 me)
  (connect sum me)
  me)
(define (inform-about-value constraint)
  (constraint 'I-have-a-value))
(define (inform-about-no-value constraint)
  (constraint 'I-lost-my-value))
(define (multiplier m1 m2 product)
  (define (process-new-value)
    (cond ((or (and (has-value? m1) (= (get-value m1) 0))
               (and (has-value? m2) (= (get-value m2) 0)))
           (set-value! product 0 me))
          ((and (has-value? m1) (has-value? m2))
           (set-value! product
                       (* (get-value m1) (get-value m2))
                       me))
          ((and (has-value? product) (has-value? m1))
           (set-value! m2
                       (/ (get-value product) (get-value m1))
                       me))
          ((and (has-value? product) (has-value? m2))
           (set-value! m1
                       (/ (get-value product) (get-value m2))
                       me))))
  (define (process-forget-value)
    (forget-value! product me)
    (forget-value! m1 me)
    (forget-value! m2 me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value)
           (process-new-value))
          ((eq? request 'I-lost-my-value)
           (process-forget-value))
          (else
           (error "Unknown request -- MULTIPLIER" request))))
  (connect m1 me)
  (connect m2 me)
  (connect product me)
  me)
(define (constant value connector)
  (define (me request)
    (error "Unknown request -- CONSTANT" request))
  (connect connector me)
  (set-value! connector value me)
  me)
(define (probe name connector)
  (define (print-probe value)
    (newline)
    (display "Probe: ")
    (display name)
    (display " = ")
    (display value))
  (define (process-new-value)
    (print-probe (get-value connector)))
  (define (process-forget-value)
    (print-probe "?"))
  (define (me request)
    (cond ((eq? request 'I-have-a-value)
           (process-new-value))
          ((eq? request 'I-lost-my-value)
           (process-forget-value))
          (else
           (error "Unknown request -- PROBE" request))))
  (connect connector me)
  me)
(define (make-connector)
  (let ((value #f) (informant #f) (constraints '()))
    (define (set-my-value newval setter)
      (cond ((not (has-value? me))
             (set! value newval)
             (set! informant setter)
             (for-each-except setter
                              inform-about-value
                              constraints))
            ((not (= value newval))
             (error "Contradiction" (list value newval)))
            (else 'ignored)))
    (define (forget-my-value retractor)
      (if (eq? retractor informant)
          (begin (set! informant #f)
                 (for-each-except retractor
                                  inform-about-no-value
                                  constraints))
          'ignored))
    (define (connect new-constraint)
      (if (not (memq new-constraint constraints))
          (set! constraints 
                (cons new-constraint constraints)))
      (if (has-value? me)
          (inform-about-value new-constraint))
      'done)
    (define (me request)
      (cond ((eq? request 'has-value?)
             (if informant #t #f))
            ((eq? request 'value) value)
            ((eq? request 'set-value!) set-my-value)
            ((eq? request 'forget) forget-my-value)
            ((eq? request 'connect) connect)
            (else (error "Unknown operation -- CONNECTOR"
                         request))))
    me))
(define (for-each-except exception procedure list)
  (define (loop items)
    (cond ((null? items) 'done)
          ((eq? (car items) exception) (loop (cdr items)))
          (else (procedure (car items))
                (loop (cdr items)))))
  (loop list))
(define (has-value? connector)
  (connector 'has-value?))
(define (get-value connector)
  (connector 'value))
(define (set-value! connector new-value informant)
  ((connector 'set-value!) new-value informant))
(define (forget-value! connector retractor)
  ((connector 'forget) retractor))
(define (connect connector new-constraint)
  ((connector 'connect) new-constraint))

; Solution:
(define (averager a b result)
  (let ((sum  (make-connector))
	   (half (make-connector)))
    (adder a b sum)
    (constant 0.5 half)
    (multiplier sum half result)
    'ok))
; Test:
(define i1 (make-connector))
(define i2 (make-connector))
(define o (make-connector))
(probe "Averager output" o)
(averager i1 i2 o)
(set-value! i1 11 'user)
(set-value! i2 25 'user)
; Probe: Averager output = 18.
(set-value! i2 13 'user)
; *** ERROR IN (console)@212.1 -- Contradiction (25 13)
(forget-value! i2 'user)
; Probe: Averager output = ?
(set-value! i2 13 'user)
; Probe: Averager output = 12.

;-- 3.34
; Sounds good, Louis. Let's try!
(define i (make-connector))
(define o (make-connector))
(probe "i" i)
(probe "o" o)
(define (squarer a b)
  (multiplier a a b))
(squarer i o)
(set-value! i 5 'user)
; Probe: o = 25
; Probe: i = 5
; Awesome! Let's try the other way around!
(forget-value! i 'user)
; Probe: o = ?
; Probe: i = ?
(set-value! o 25 'user)
; Probe: b = 25
; Okay, so this won't work. Neither a (the first input of the multiplier) nor,
; well, a (the second input of the multiplier) has any value, so multiplier
; can't guess both inputs from the output alone.
; And this is where everything breaks down: we know the inverse of squaring,
; i.e. square roots, so we should be able to compute the input from the output.
; It makes no sense whatsoever to have a squarer with an output value and no
; input value.
; But let's experiment some more!
(set-value! i 5 'user)
; Probe: i = 5
; Still ~working! And why wouldn't it? The system is coherent.
(forget-value! i 'user)
; Probe: i = ?
(set-value! i 10 'user)
; *** ERROR IN loop, (console)@134.17 -- Contradiction (25 100)

;-- 3.35
(define (squarer a b)
  (define (process-new-value)
    (if (has-value? b)
	 (if (< (get-value b) 0)
	   (error "square less than 0 -- SQUARER" (get-value b))
	   (set-value! a (sqrt (get-value b)) me))
	 (if (has-value? a)
	   (set-value! b (* (get-value a) (get-value a)) me))))
  (define (process-forget-value)
    (forget-value! a me)
    (forget-value! b me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value)
		 (process-new-value))
		((eq? request 'I-lost-my-value)
		 (process-forget-value))
		(else
		  (error "Unknown request -- SQUARER" request))))
  (connect a me)
  (connect b me)
  me)

; Test:
(define i (make-connector))
(define o (make-connector))
(probe "i" i)
(probe "o" o)
(squarer i o)
(set-value! i 5 'user)                                  
; Probe: o = 25
; Probe: i = 5
(set-value! o 555 'user)
; *** ERROR IN (console)@386.1 -- Contradiction (25 30)
(forget-value! i 'user)
; Probe: o = ?
; Probe: i = ?
(set-value! o 36 'user)
; Probe: i = 6
; Probe: o = 36

;-- 3.36
; #Environment diagram.

;-- 3.37
; Given:
(define (c+ x y)
  (let ((z (make-connector)))
    (adder x y z)
    z))
; The other ones are:
(define (c* x y)
  (let ((z (make-connector)))
    (multiplier x y z)
    z))
(define (cv x)
  (let ((z (make-connector)))
    (constant x z)
    z))
; We will need to define substracter and diviser if we want to implement c- and
; c/.
(define (substracter a1 a2 sum)
  (define (process-new-value)
    (cond ((and (has-value? a1) (has-value? a2))
           (set-value! sum
                       (- (get-value a1) (get-value a2))
                       me))
          ((and (has-value? a1) (has-value? sum))
           (set-value! a2
                       (- (get-value a1) (get-value sum))
                       me))
          ((and (has-value? a2) (has-value? sum))
           (set-value! a1
                       (+ (get-value sum) (get-value a2))
                       me))))
  (define (process-forget-value)
    (forget-value! sum me)
    (forget-value! a1 me)
    (forget-value! a2 me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value)  
           (process-new-value))
          ((eq? request 'I-lost-my-value) 
           (process-forget-value))
          (else 
           (error "Unknown request -- SUBSTRACTER" request))))
  (connect a1 me)
  (connect a2 me)
  (connect sum me)
  me)
(define (divider m1 m2 product)
  (define (process-new-value)
    (cond ((or (and (has-value? m1) (= (get-value m1) 0))
               (and (has-value? m2) (= (get-value m2) 0)))
           (set-value! product 0 me))
          ((and (has-value? m1) (has-value? m2))
           (set-value! product
                       (/ (get-value m1) (get-value m2))
                       me))
          ((and (has-value? product) (has-value? m1))
           (set-value! m2
                       (/ (get-value m1) (get-value product))
                       me))
          ((and (has-value? product) (has-value? m2))
           (set-value! m1
                       (* (get-value product) (get-value m2))
                       me))))
  (define (process-forget-value)
    (forget-value! product me)
    (forget-value! m1 me)
    (forget-value! m2 me)
    (process-new-value))
  (define (me request)
    (cond ((eq? request 'I-have-a-value)
           (process-new-value))
          ((eq? request 'I-lost-my-value)
           (process-forget-value))
          (else
           (error "Unknown request -- DIVIDER" request))))
  (connect m1 me)
  (connect m2 me)
  (connect product me)
  me)

(define (c- x y)
  (let ((z (make-connector)))
    (substracter x y z)
    z))
(define (c/ x y)
  (let ((z (make-connector)))
    (divider x y z)
    z))

; Test:
(define (celsius-fahrenheit-converter x)
  (c+ (c* (c/ (cv 9) (cv 5))
          x)
      (cv 32)))
(define C (make-connector))
(define F (celsius-fahrenheit-converter C))
(probe "Celsius" C)
(probe "Fahrenheit" F)
(set-value! C 22. 'user)
; Probe: Celsius = 22.
; Probe: Fahrenheit = 71.6
(set-value! F 90. 'user)
; *** ERROR IN (console)@493.1 -- Contradiction (71.6 90.)
(forget-value! C 'user)
; Probe: Celsius = ?
; Probe: Fahrenheit = ?
(set-value! F 90. 'user)
; Probe: Fahrenheit = 90.
; Probe: Celsius = 32.22222222222222

;-- 3.38
; The possible values if the operations are done sequentially are:
; x1 = (100 / 2) - 20 + 10      = 40        (Mary Paul Peter)
; x2 = ((100 - 20) / 2) + 10    = 50        (Paul Mary Peter)
; x3 = ((100 + 10) / 2) - 20    = 35        (Peter Mary Paul)
; x4 = (100 + 10 - 20) / 2      = 45        (Peter Paul Mary)
; Because Peter and Paul's operation are commutable:
; (Peter Paul Mary) == (Paul Peter Mary) and
; (Mary Paul Peter) == (Mary Peter Paul).
; Hence there are not 3! different permutations, but only 4.

; Other values if the operations weren't done sequentially could be:
; If all access the amount at the same time and Mary sets it last: 50
; If all access the amount at the same time and Peter sets it last: 110
; If Peter accesses and updates (110), then Mary reads, then Paul reads and
; updates, then Mary updates: 55
; Etc.

;-- 3.39
; First lambda then second lambda: 101
; Second lambda then first lambda: 121

;-- 3.40
; The operations are:
; Lambda 1: read x once, read x another time, then set
; Lambda 2: read x once, read x another time, read x a third time, then set
; Let's call these r11, r12, r21, r22, r23, s1 and s2
; There are 7! = 5040 possible permutations; here are a few possible results:
; 100
; 1000
; 10000
; 1000000

; If the operations are sequential, the two only possible values are:
; (10*10*10) * (10*10*10) = 1 000 000
; (10*10) * (10*10) * (10*10) = 1 000 000

;-- 3.41
; No. As long as (withdraw) and (deposit) are shielded from each other, the
; amount returned by (balance) will always be either before or after the
; modifying operation. At worst, (balance) might return a slightly outdated
; balance if the concurrent modifying operation didn't have the time to set the
; new amount.

;-- 3.42
; There is no difference in practice between the two versions.

;-- 3.43
; If the processes are run sequentially, there is absolutely no chance that the
; balances will end mixed up simply because there is no critical section.

; If the processes are run with the first account-exchange method, things like
; these might happen:
; - Process1 wants to swap Account1 (at $10) and Account3 (at $30).
;   It computes the difference to be $20. Pauses.
; - Process2 wants to swap Account2 (at $20) and Account3 (at $30).
;   It computes the difference to be $10. Pauses.
; - Process1 proceeds to withdraw $20 from Account3 and deposits it to
;   Account1. Ends.
; - Process2 proceeds to withdraw $10 from Account3 and deposits it to
;   Account2. Ends.
; Final balances: Account1 = $30, Account2 = $30, and Account3 = $0.
; Sum is $60, i.e. constant. We're good.

; If the processes are not run sequentially at all, the balances might all end
; up at either $10, $20 or $30 according to chance; exactly as in the previous
; exercises.

;-- 3.44
; Louis is wrong. The money transfer is simpler than the money exchange, and
; does not need to be serialized further. Incidentally, a safe money exchange
; would be two serialized money transfers.


