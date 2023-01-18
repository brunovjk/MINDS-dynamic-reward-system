# MINDS-dynamic-reward-system

testCalculateRewardsPerSecond:
forge test --match-contract CalcRewardsPerSecondTest -vvvv

Task: To create an automated dynamic reward system using Chainlink automation.

Overview: The automated dynamic reward system will track MIND+ performance and adjust the rewards based on the percent change using Chainlink automation.

Problem: The current system is a spreadsheet that does all the calculations, and I have to call the contract and change the rewards manually. It works, but I’m human, and sometimes I forget.

Solution: Chainlink automation. This will allow the protocol to run on autopilot without human intervention to adjust daily rewards.

How should it work?
The rewards will change every 24hrs based on the performance of MIND+. If MIND+ is 1% positive within the 24hr period, the rewards will increase in the scale by 1% from the previous percentage, i.e., 24hrs ago, the percent change was -3%, and 24hrs later is +1%, so the new percentage is -2%.

The rewards cannot be lower than 0.02 MIND+ per day and cannot be higher than 0.1 MIND+ per day. The smart contract has a safety function with these numbers set as the minimum and maximum. The chainlink automation should have the rewards structure below. It goes from negative 10% to positive 15%. As you can see, if the percentage change in one day is beyond -10%, the rewards will default to 0.02 because that is the minimum, and the same goes with a positive beyond 15%; the max reward is 0.1.

\*Rewards will dynamically adjust daily (24hr) based on the table below from the last 24hr percent change.

<table class="tg">
<thead>
  <tr>
    <th class="tg-183e"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">Percentage</span></th>
    <th class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">Rewards </span></th>
    <th class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">Numbers of Places</span></th>
  </tr>
</thead>
<tbody>
  <tr>
    <td class="tg-ianp"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-10.00</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.02</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">1</span></td>
  </tr>  <tr>
    <td class="tg-ianp"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-9.63</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.02574545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">2</span></td>
  </tr>
  <tr>
    <td class="tg-uyjh"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-9.26</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.02714545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">3</span></td>
  </tr>
  <tr>
    <td class="tg-vzpl"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-8.89</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.02854545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">4</span></td>
  </tr>
  <tr>
    <td class="tg-ox36"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-8.52</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.02994545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">5</span></td>
  </tr>
  <tr>
    <td class="tg-j0pp"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-8.15</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03134545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">6</span></td>
  </tr>
  <tr>
    <td class="tg-mbqv"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-7.78</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03274545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">7</span></td>
  </tr>
  <tr>
    <td class="tg-moe0"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-7.41</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03414545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">8</span></td>
  </tr>
  <tr>
    <td class="tg-atvf"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-7.04</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03554545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">9</span></td>
  </tr>
  <tr>
    <td class="tg-meav"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-6.67</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03694545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">10</span></td>
  </tr>
  <tr>
    <td class="tg-8wzr"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-6.30</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03834545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">11</span></td>
  </tr>
  <tr>
    <td class="tg-ckpw"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-5.93</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.03974545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">12</span></td>
  </tr>
  <tr>
    <td class="tg-cp4f"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-5.56</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04114545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">13</span></td>
  </tr>
  <tr>
    <td class="tg-im67"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-5.19</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04254545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">14</span></td>
  </tr>
  <tr>
    <td class="tg-sqq9"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-4.81</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04394545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">15</span></td>
  </tr>
  <tr>
    <td class="tg-jjak"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-4.44</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04534545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">16</span></td>
  </tr>
  <tr>
    <td class="tg-zlvt"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-4.07</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04674545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">17</span></td>
  </tr>
  <tr>
    <td class="tg-dhu9"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-3.70</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04814545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">18</span></td>
  </tr>
  <tr>
    <td class="tg-4aek"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-3.33</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.04954545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">19</span></td>
  </tr>
  <tr>
    <td class="tg-eurt"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-2.96</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05094545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">20</span></td>
  </tr>
  <tr>
    <td class="tg-hto0"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-2.59</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05234545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">21</span></td>
  </tr>
  <tr>
    <td class="tg-qx0i"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-2.22</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05374545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">22</span></td>
  </tr>
  <tr>
    <td class="tg-qg8z"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-1.85</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05514545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">23</span></td>
  </tr>
  <tr>
    <td class="tg-amty"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-1.48</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05654545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">24</span></td>
  </tr>
  <tr>
    <td class="tg-t0dl"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-1.11</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05794545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">25</span></td>
  </tr>
  <tr>
    <td class="tg-ia7w"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-0.74</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.05934545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">26</span></td>
  </tr>
  <tr>
    <td class="tg-d12q"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">-0.37</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06074545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">27</span></td>
  </tr>
  <tr>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.00</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06214545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">28</span></td>
  </tr>
  <tr>
    <td class="tg-dugi"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.556</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06354545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">29</span></td>
  </tr>
  <tr>
    <td class="tg-bfay"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">1.111</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06494545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">30</span></td>
  </tr>
  <tr>
    <td class="tg-xa3i"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">1.67</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06634545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">31</span></td>
  </tr>
  <tr>
    <td class="tg-p4zm"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">2.22</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06774545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">32</span></td>
  </tr>
  <tr>
    <td class="tg-7tfv"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">2.78</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.06914545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">33</span></td>
  </tr>
  <tr>
    <td class="tg-zvyw"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">3.33</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07054545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">34</span></td>
  </tr>
  <tr>
    <td class="tg-8a0t"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">3.89</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07194545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">35</span></td>
  </tr>
  <tr>
    <td class="tg-o2jk"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">4.44</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07334545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">36</span></td>
  </tr>
  <tr>
    <td class="tg-9pxb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">5.00</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07474545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">37</span></td>
  </tr>
  <tr>
    <td class="tg-n20g"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">5.56</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07614545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">38</span></td>
  </tr>
  <tr>
    <td class="tg-r8o4"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">6.11</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07754545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">39</span></td>
  </tr>
  <tr>
    <td class="tg-olkv"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">6.67</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.07894545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">40</span></td>
  </tr>
  <tr>
    <td class="tg-jk84"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">7.22</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08034545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">41</span></td>
  </tr>
  <tr>
    <td class="tg-si87"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">7.78</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08174545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">42</span></td>
  </tr>
  <tr>
    <td class="tg-0oem"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">8.33</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08314545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">43</span></td>
  </tr>
  <tr>
    <td class="tg-u9j7"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">8.89</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08454545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">44</span></td>
  </tr>
  <tr>
    <td class="tg-rctf"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">9.44</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08594545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">45</span></td>
  </tr>
  <tr>
    <td class="tg-v2zu"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">10.00</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08734545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">46</span></td>
  </tr>
  <tr>
    <td class="tg-4oxd"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">10.56</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.08874545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">47</span></td>
  </tr>
  <tr>
    <td class="tg-bm0b"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">11.11</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09014545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">48</span></td>
  </tr>
  <tr>
    <td class="tg-e5a9"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">11.67</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09154545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">49</span></td>
  </tr>
  <tr>
    <td class="tg-aip1"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">12.22</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09294545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">50</span></td>
  </tr>
  <tr>
    <td class="tg-mwmv"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">12.78</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09434545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">51</span></td>
  </tr>
  <tr>
    <td class="tg-qk2i"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">13.33</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09574545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">52</span></td>
  </tr>
  <tr>
    <td class="tg-zj5l"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">13.89</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09714545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">53</span></td>
  </tr>
  <tr>
    <td class="tg-xefy"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">14.44</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.09854545455</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">54</span></td>
  </tr>
  <tr>
    <td class="tg-1elw"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">15.00</span></td>
    <td class="tg-lqy6"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">0.1</span></td>
    <td class="tg-eelb"><span style="font-weight:400;font-style:normal;text-decoration:none;color:#000;background-color:transparent">55</span></td>
  </tr>
</tbody>
</table>

The smart contract should:

1. Track MIND+ 24hr performance
2. Calculate daily rewards from the last percent change to the new one. (I assume you might need something in the smart contract to store the last percent change to calculate the new rewards from the last percent change if that makes sense).
3. Convert daily rewards to per the second format: Example below

Rewards Formula: eth => wei divided by seconds per day = value

For example, 0.06214545455 eth => 62145454550000000 Wei / 86400 = 719276094329 ← this is the same as 0.0.06214545455 eth => 62145454550000000 Wei, but 719276094329 is the number that would go in line 37 of the brain-management-contract.

4. Call the brain-management-contract
   Let's say the rewards calculated are 0.06214545455, that number the brain-management smart contract does not like it. The smart contract only accepts values in per-second format.
