### Security steps taken to ensure the contracts are not susceptible to common attacks

1. To protect against Denial of Service attacks, loops were not used.  
2. To protect against integer overflow/underflow, OpenZeppelin's 'min' function was used.  

Note: an attempt was made to use OpenZeppelin's SafeMath library for multiplication and division.  
However, I found these linkages inconsistent between the development Remix and VS Code. 
OpenZeppelin's code for the 'min' function was copied and pasted directly from the Math library. 
The same was not done, however, for the safemath 'mul' and 'div' functions which did not compile or behave as anticipated.  
So in the two places where there is multiplication and division, the * and / operators were used. 
